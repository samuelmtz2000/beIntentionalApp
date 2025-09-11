import { Router } from "express";
import prisma from "../lib/prisma";

const DEFAULT_USER_ID = "seed-user-1";
const router = Router();

// Unified archive listing: areas, habits, bad habits
router.get("/", async (_req, res) => {
  const [areas, habits, badHabits] = await Promise.all([
    prisma.area.findMany({ where: { userId: DEFAULT_USER_ID, deletedAt: { not: null } } }),
    prisma.goodHabit.findMany({ where: { deletedAt: { not: null } }, include: { area: true } }),
    prisma.badHabit.findMany({ where: { deletedAt: { not: null } }, include: { area: true } }),
  ]);
  res.json({ areas, habits, badHabits });
});

export default router;

