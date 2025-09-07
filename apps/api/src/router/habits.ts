import { Router } from "express";
import { z } from "zod";
import prisma from "../lib/prisma";

const router = Router();

const habitSchema = z.object({
  areaId: z.string(),
  name: z.string().min(1),
  xpReward: z.number().int().min(1),
  coinReward: z.number().int().min(0),
  cadence: z.string().optional(),
  isActive: z.boolean().default(true),
});

router.get("/", async (_req, res) => {
  const habits = await prisma.goodHabit.findMany({ include: { area: true } });
  res.json(habits);
});

router.post("/", async (req, res) => {
  const parsed = habitSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  const habit = await prisma.goodHabit.create({ data: parsed.data });
  res.status(201).json(habit);
});

router.put("/:id", async (req, res) => {
  const parsed = habitSchema.partial().safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  try {
    const habit = await prisma.goodHabit.update({ where: { id: req.params.id }, data: parsed.data });
    res.json(habit);
  } catch {
    res.status(404).json({ message: "Habit not found" });
  }
});

router.delete("/:id", async (req, res) => {
  try {
    await prisma.goodHabit.delete({ where: { id: req.params.id } });
    res.status(204).end();
  } catch {
    res.status(404).json({ message: "Habit not found" });
  }
});

export default router;

