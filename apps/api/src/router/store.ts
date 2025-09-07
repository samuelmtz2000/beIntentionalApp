import { Router } from "express";
import prisma from "../lib/prisma";

const DEFAULT_USER_ID = "seed-user-1";
const router = Router();

router.get("/controlled-bad-habits", async (_req, res) => {
  const items = await prisma.badHabit.findMany({ where: { controllable: true, isActive: true } });
  res.json(items);
});

router.get("/cosmetics", async (_req, res) => {
  const items = await prisma.cosmetic.findMany();
  res.json(items);
});

router.post("/cosmetics/:id/buy", async (req, res) => {
  const cosmetic = await prisma.cosmetic.findUnique({ where: { id: req.params.id } });
  if (!cosmetic) return res.status(404).json({ message: "Cosmetic not found" });

  const user = await prisma.user.findUnique({ where: { id: DEFAULT_USER_ID } });
  if (!user) return res.status(404).json({ message: "User not found" });

  const owned = await prisma.userCosmetic.findUnique({ where: { userId_cosmeticId: { userId: DEFAULT_USER_ID, cosmeticId: cosmetic.id } } });
  if (owned) return res.status(409).json({ message: "Already owned" });

  if (user.coins < cosmetic.price) return res.status(400).json({ message: "Insufficient coins" });

  const [uc] = await prisma.$transaction([
    prisma.user.update({ where: { id: DEFAULT_USER_ID }, data: { coins: { decrement: cosmetic.price } } }),
    prisma.transaction.create({ data: { userId: DEFAULT_USER_ID, amount: -cosmetic.price, type: "spend", meta: { source: "cosmetic", cosmeticId: cosmetic.id } } }),
    prisma.userCosmetic.create({ data: { userId: DEFAULT_USER_ID, cosmeticId: cosmetic.id } }),
  ]);

  res.json({ ok: true, coins: uc.coins });
});

export default router;

