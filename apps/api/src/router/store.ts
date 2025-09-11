import { Router } from "express";
import prisma from "../lib/prisma";

const DEFAULT_USER_ID = "seed-user-1";
const router = Router();

// Purchase a controlled bad habit so future records avoid life penalty
router.post("/bad-habits/:id/buy", async (req, res) => {
  const bad = await prisma.badHabit.findFirst({ where: { id: req.params.id, deletedAt: null } });
  if (!bad) return res.status(404).json({ message: "Bad habit not found" });
  // All bad habits are purchasable; controllable flag is ignored

  const user = await prisma.user.findUnique({ where: { id: DEFAULT_USER_ID } });
  if (!user) return res.status(404).json({ message: "User not found" });

  const price = bad.coinCost || 0;
  if (user.coins < price) return res.status(400).json({ message: "Insufficient coins" });

  const [updatedUser] = await prisma.$transaction([
    prisma.user.update({ where: { id: DEFAULT_USER_ID }, data: { coins: { decrement: price } } }),
    prisma.transaction.create({ data: { userId: DEFAULT_USER_ID, amount: -price, type: "spend", meta: { source: "badHabitPurchase", badHabitId: bad.id } } }),
    prisma.userOwnedBadHabit.create({ data: { userId: DEFAULT_USER_ID, badHabitId: bad.id } }),
  ]);

  res.json({ ok: true, coins: updatedUser.coins });
});

export default router;
