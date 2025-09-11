import { Router } from "express";
import { z } from "zod";
import prisma from "../lib/prisma";

const router = Router();

const badHabitSchema = z.object({
  areaId: z.string().optional(),
  name: z.string().min(1),
  lifePenalty: z.number().int().min(1),
  controllable: z.boolean(),
  coinCost: z.number().int().min(0),
  isActive: z.boolean().default(true),
});

router.get("/", async (_req, res) => {
  const items = await prisma.badHabit.findMany({ where: { deletedAt: null }, include: { area: true } });
  res.json(items);
});

router.get("/:id", async (req, res) => {
  const item = await prisma.badHabit.findFirst({ where: { id: req.params.id, deletedAt: null }, include: { area: true } });
  if (!item) return res.status(404).json({ message: "Bad habit not found" });
  res.json(item);
});

router.post("/", async (req, res) => {
  const parsed = badHabitSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  if (parsed.data.areaId) {
    const area = await prisma.area.findFirst({ where: { id: parsed.data.areaId, deletedAt: null } });
    if (!area) return res.status(400).json({ message: "Area not found or archived" });
  }
  const item = await prisma.badHabit.create({ data: parsed.data });
  res.status(201).json(item);
});

router.put("/:id", async (req, res) => {
  const parsed = badHabitSchema.partial().safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  try {
    const existing = await prisma.badHabit.findFirst({ where: { id: req.params.id, deletedAt: null } });
    if (!existing) return res.status(404).json({ message: "Bad habit not found" });
    if (parsed.data.areaId) {
      const area = await prisma.area.findFirst({ where: { id: parsed.data.areaId, deletedAt: null } });
      if (!area) return res.status(400).json({ message: "Area not found or archived" });
    }
    const item = await prisma.badHabit.update({ where: { id: req.params.id }, data: parsed.data });
    res.json(item);
  } catch {
    res.status(404).json({ message: "Bad habit not found" });
  }
});

router.delete("/:id", async (req, res) => {
  try {
    await prisma.badHabit.update({ where: { id: req.params.id }, data: { deletedAt: new Date() } });
    res.status(204).end();
  } catch {
    res.status(404).json({ message: "Bad habit not found" });
  }
});

router.post("/:id/restore", async (req, res) => {
  try {
    const item = await prisma.badHabit.update({ where: { id: req.params.id }, data: { deletedAt: null } });
    res.json(item);
  } catch {
    res.status(404).json({ message: "Bad habit not found" });
  }
});

export default router;
