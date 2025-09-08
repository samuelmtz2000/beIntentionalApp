import { Router } from "express";
import prisma from "../lib/prisma";
import { computeLevelFromTotalXP } from "../lib/leveling";

const DEFAULT_USER_ID = "seed-user-1";
const router = Router();

router.get("/", async (_req, res) => {
  const user = await prisma.user.findUnique({ where: { id: DEFAULT_USER_ID } });
  if (!user) return res.status(404).json({ message: "User not found" });

  const [areas, levels, owned] = await Promise.all([
    prisma.area.findMany({ where: { userId: DEFAULT_USER_ID } }),
    prisma.areaLevel.findMany({ where: { userId: DEFAULT_USER_ID } }),
    prisma.userOwnedBadHabit.findMany({ where: { userId: DEFAULT_USER_ID }, include: { badHabit: true } }),
  ]);

  const byArea = new Map(levels.map((l) => [l.areaId, l]));
  const areasView = areas.map((a) => ({
    areaId: a.id,
    name: a.name,
    xpPerLevel: a.xpPerLevel,
    level: byArea.get(a.id)?.level ?? 1,
    xp: byArea.get(a.id)?.xp ?? 0,
  }));

  // Aggregate owned bad habits into counts
  const counts = new Map<string, { id: string; name: string; count: number }>();
  for (const u of owned) {
    const key = u.badHabit.id;
    const curr = counts.get(key);
    if (curr) curr.count += 1;
    else counts.set(key, { id: u.badHabit.id, name: u.badHabit.name, count: 1 });
  }

  // Compute global level/xp from logs if configured
  let gLevel = user.level;
  let gXP = user.xp;
  if (user.xpComputationMode === "logs") {
    const logs = await prisma.habitLog.findMany({
      where: { userId: DEFAULT_USER_ID },
      include: { habit: { select: { xpReward: true } } },
    });
    const total = logs.reduce((sum, l) => sum + (l.habit?.xpReward || 0), 0);
    const resLv = computeLevelFromTotalXP(total, user.xpPerLevel, user.levelCurve as any, user.levelMultiplier);
    gLevel = resLv.level;
    gXP = resLv.xp;
  }

  res.json({
    life: user.life,
    coins: user.coins,
    level: gLevel,
    xp: gXP,
    xpPerLevel: user.xpPerLevel,
    config: {
      levelCurve: user.levelCurve,
      levelMultiplier: user.levelMultiplier,
      xpComputationMode: user.xpComputationMode,
    },
    areas: areasView,
    ownedBadHabits: Array.from(counts.values()),
  });
});

export default router;
