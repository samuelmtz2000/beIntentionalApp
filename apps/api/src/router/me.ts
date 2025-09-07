import { Router } from "express";
import prisma from "../lib/prisma";

const DEFAULT_USER_ID = "seed-user-1";
const router = Router();

router.get("/", async (_req, res) => {
  const user = await prisma.user.findUnique({ where: { id: DEFAULT_USER_ID } });
  if (!user) return res.status(404).json({ message: "User not found" });

  const [areas, levels, owned] = await Promise.all([
    prisma.area.findMany({ where: { userId: DEFAULT_USER_ID } }),
    prisma.areaLevel.findMany({ where: { userId: DEFAULT_USER_ID } }),
    prisma.userCosmetic.findMany({ where: { userId: DEFAULT_USER_ID }, include: { cosmetic: true } }),
  ]);

  const byArea = new Map(levels.map((l) => [l.areaId, l]));
  const areasView = areas.map((a) => ({
    areaId: a.id,
    name: a.name,
    xpPerLevel: a.xpPerLevel,
    level: byArea.get(a.id)?.level ?? 1,
    xp: byArea.get(a.id)?.xp ?? 0,
  }));

  res.json({
    life: user.life,
    coins: user.coins,
    areas: areasView,
    cosmeticsOwned: owned.map((u) => ({ id: u.cosmetic.id, category: u.cosmetic.category, key: u.cosmetic.key })),
  });
});

export default router;

