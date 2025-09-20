import { Router } from "express";
import prisma from "../lib/prisma";
import { computeGeneralStreak } from "../lib/streaks";
import { applyHabitCompletion } from "../lib/leveling";

const DEFAULT_USER_ID = "seed-user-1";
const router = Router();

router.post("/habits/:id/complete", async (req, res) => {
  // block actions if user not in active state
  const actingUser = await prisma.user.findUnique({ where: { id: DEFAULT_USER_ID } });
  if (!actingUser) return res.status(404).json({ message: "User not found" });
  if (actingUser.gameState !== "active") return res.status(409).json({ message: "Game is not active. Complete recovery to continue." });

  const habit = await prisma.goodHabit.findFirst({ where: { id: req.params.id, deletedAt: null }, include: { area: true } });
  if (!habit || !habit.area || (habit.area as any).deletedAt) return res.status(404).json({ message: "Habit not found" });

  // get or create AreaLevel
  let areaLevel = await prisma.areaLevel.findUnique({ where: { userId_areaId: { userId: DEFAULT_USER_ID, areaId: habit.areaId } } });
  if (!areaLevel) {
    areaLevel = await prisma.areaLevel.create({ data: { userId: DEFAULT_USER_ID, areaId: habit.areaId, level: 1, xp: 0 } });
  }

  // compute next area level/xp
  const nextArea = applyHabitCompletion(
    areaLevel.xp,
    areaLevel.level,
    habit.xpReward,
    habit.area.xpPerLevel,
    habit.area.levelCurve as any,
    (habit.area as any).levelMultiplier ?? 1.5
  );

  // fetch user to compute global leveling or skip if logs-mode
  const user = actingUser;
  const logsMode = (user.xpComputationMode as any) === "logs";
  const nextUser = logsMode
    ? { level: user.level, xp: user.xp } // do not update stored xp/level when computing from logs
    : applyHabitCompletion(user.xp, user.level, habit.xpReward, user.xpPerLevel, user.levelCurve as any, user.levelMultiplier ?? 1.5);

  const [updatedLevel, updatedUser, _log, _tx] = await prisma.$transaction([
    prisma.areaLevel.update({ where: { id: areaLevel.id }, data: { level: nextArea.level, xp: nextArea.xp } }),
    prisma.user.update({
      where: { id: DEFAULT_USER_ID },
      data: logsMode
        ? { coins: { increment: habit.coinReward } }
        : { coins: { increment: habit.coinReward }, level: nextUser.level, xp: nextUser.xp },
    }),
    prisma.habitLog.create({ data: { userId: DEFAULT_USER_ID, habitId: habit.id } }),
    prisma.transaction.create({ data: { userId: DEFAULT_USER_ID, amount: habit.coinReward, type: "earn", meta: { source: "habit", habitId: habit.id } } }),
  ]);

  // Also compute today's streak snapshot for instant client UI updates
  const today = new Date();
  const fmt = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
  const key = fmt(today);
  const streak = await computeGeneralStreak({ userId: DEFAULT_USER_ID, from: key, to: key });
  res.json({
    areaLevel: updatedLevel,
    user: { coins: updatedUser.coins, level: updatedUser.level, xp: updatedUser.xp, xpPerLevel: updatedUser.xpPerLevel },
    today: { ...streak.days[0], currentGeneralStreak: streak.currentCount },
  });
});

router.post("/bad-habits/:id/record", async (req, res) => {
  // block actions if user not in active state
  const actingUser = await prisma.user.findUnique({ where: { id: DEFAULT_USER_ID } });
  if (!actingUser) return res.status(404).json({ message: "User not found" });
  if (actingUser.gameState !== "active") return res.status(409).json({ message: "Game is not active. Complete recovery to continue." });

  const bad = await prisma.badHabit.findFirst({ where: { id: req.params.id, deletedAt: null } });
  if (!bad) return res.status(404).json({ message: "Bad habit not found" });

  let avoidedPenalty = false;
  let userAfter;

  // Always try to consume one credit (inventory) if available, regardless of controllable flag
  const credit = await prisma.userOwnedBadHabit.findFirst({
    where: { userId: DEFAULT_USER_ID, badHabitId: bad.id },
    orderBy: { purchasedAt: "asc" },
  });
  if (credit) {
    avoidedPenalty = true;
    await prisma.userOwnedBadHabit.delete({ where: { id: credit.id } });
    userAfter = await prisma.user.findUnique({ where: { id: DEFAULT_USER_ID } });
  }

  if (!avoidedPenalty) {
    userAfter = await prisma.user.update({ where: { id: DEFAULT_USER_ID }, data: { life: { decrement: bad.lifePenalty } } });
  }

  await prisma.badHabitLog.create({ data: { userId: DEFAULT_USER_ID, badHabitId: bad.id, avoidedPenalty } });

  // Trigger Game Over when life reaches 0 or below
  if (!avoidedPenalty && userAfter && userAfter.life <= 0) {
    const now = new Date();
    const current = await prisma.user.findUnique({ where: { id: DEFAULT_USER_ID } });
    if (current && current.gameState === "active") {
      await prisma.user.update({
        where: { id: DEFAULT_USER_ID },
        data: {
          gameState: "game_over",
          gameOverAt: now,
          recoveryStartedAt: now,
          recoveryDistance: 0,
          totalGameOvers: { increment: 1 },
        },
      });
    }
  }

  // Also compute today's streak snapshot for instant client UI updates
  const today = new Date();
  const fmt = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
  const key = fmt(today);
  const streak = await computeGeneralStreak({ userId: DEFAULT_USER_ID, from: key, to: key });
  res.json({ user: { life: userAfter!.life }, avoidedPenalty, today: { ...streak.days[0], currentGeneralStreak: streak.currentCount } });
});

export default router;
