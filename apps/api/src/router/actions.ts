import { Router } from "express";
import prisma from "../lib/prisma";
import { applyHabitCompletion } from "../lib/leveling";

const DEFAULT_USER_ID = "seed-user-1";
const router = Router();

router.post("/habits/:id/complete", async (req, res) => {
  const habit = await prisma.goodHabit.findUnique({ where: { id: req.params.id }, include: { area: true } });
  if (!habit || !habit.area) return res.status(404).json({ message: "Habit not found" });

  // get or create AreaLevel
  let areaLevel = await prisma.areaLevel.findUnique({ where: { userId_areaId: { userId: DEFAULT_USER_ID, areaId: habit.areaId } } });
  if (!areaLevel) {
    areaLevel = await prisma.areaLevel.create({ data: { userId: DEFAULT_USER_ID, areaId: habit.areaId, level: 1, xp: 0 } });
  }

  const next = applyHabitCompletion(areaLevel.xp, areaLevel.level, habit.xpReward, habit.area.xpPerLevel, habit.area.levelCurve as any);

  const [updatedLevel, updatedUser, _log, _tx] = await prisma.$transaction([
    prisma.areaLevel.update({ where: { id: areaLevel.id }, data: { level: next.level, xp: next.xp } }),
    prisma.user.update({ where: { id: DEFAULT_USER_ID }, data: { coins: { increment: habit.coinReward } } }),
    prisma.habitLog.create({ data: { userId: DEFAULT_USER_ID, habitId: habit.id } }),
    prisma.transaction.create({ data: { userId: DEFAULT_USER_ID, amount: habit.coinReward, type: "earn", meta: { source: "habit", habitId: habit.id } } }),
  ]);

  res.json({ areaLevel: updatedLevel, user: { coins: updatedUser.coins } });
});

router.post("/bad-habits/:id/record", async (_req, res) => {
  const bad = await prisma.badHabit.findUnique({ where: { id: req.params.id } });
  if (!bad) return res.status(404).json({ message: "Bad habit not found" });

  let avoidedPenalty = false;
  let userAfter;

  if (bad.controllable) {
    const owned = await prisma.userOwnedBadHabit.findUnique({ where: { userId_badHabitId: { userId: DEFAULT_USER_ID, badHabitId: bad.id } } });
    if (owned) {
      avoidedPenalty = true;
      userAfter = await prisma.user.findUnique({ where: { id: DEFAULT_USER_ID } });
    }
  }

  if (!avoidedPenalty) {
    userAfter = await prisma.user.update({ where: { id: DEFAULT_USER_ID }, data: { life: { decrement: bad.lifePenalty } } });
  }

  await prisma.badHabitLog.create({ data: { userId: DEFAULT_USER_ID, badHabitId: bad.id, avoidedPenalty } });
  res.json({ user: { life: userAfter!.life }, avoidedPenalty });
});

export default router;
