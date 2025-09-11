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
  const habits = await prisma.goodHabit.findMany({ where: { deletedAt: null }, include: { area: true } });
  res.json(habits);
});

router.get("/:id", async (req, res) => {
  const habit = await prisma.goodHabit.findFirst({ where: { id: req.params.id, deletedAt: null }, include: { area: true } });
  if (!habit) return res.status(404).json({ message: "Habit not found" });
  res.json(habit);
});

router.post("/", async (req, res) => {
  const parsed = habitSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  // Ensure target area is active
  const area = await prisma.area.findFirst({ where: { id: parsed.data.areaId, deletedAt: null } });
  if (!area) return res.status(400).json({ message: "Area not found or archived" });
  const habit = await prisma.goodHabit.create({ data: parsed.data });
  res.status(201).json(habit);
});

router.put("/:id", async (req, res) => {
  const parsed = habitSchema.partial().safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  try {
    const existing = await prisma.goodHabit.findFirst({ where: { id: req.params.id, deletedAt: null } });
    if (!existing) return res.status(404).json({ message: "Habit not found" });
    if (parsed.data.areaId) {
      const area = await prisma.area.findFirst({ where: { id: parsed.data.areaId, deletedAt: null } });
      if (!area) return res.status(400).json({ message: "Area not found or archived" });
    }
    const habit = await prisma.goodHabit.update({ where: { id: req.params.id }, data: parsed.data });
    res.json(habit);
  } catch {
    res.status(404).json({ message: "Habit not found" });
  }
});

router.delete("/:id", async (req, res) => {
  try {
    await prisma.goodHabit.update({ where: { id: req.params.id }, data: { deletedAt: new Date() } });
    res.status(204).end();
  } catch {
    res.status(404).json({ message: "Habit not found" });
  }
});

router.post("/:id/restore", async (req, res) => {
  try {
    const habit = await prisma.goodHabit.update({ where: { id: req.params.id }, data: { deletedAt: null } });
    res.json(habit);
  } catch {
    res.status(404).json({ message: "Habit not found" });
  }
});

export default router;
