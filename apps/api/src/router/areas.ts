import { Router } from "express";
import { z } from "zod";
import prisma from "../lib/prisma";

const DEFAULT_USER_ID = "seed-user-1";

const areaSchema = z.object({
  name: z.string().min(1),
  icon: z.string().optional(),
  xpPerLevel: z.number().int().min(10),
  levelCurve: z.enum(["linear", "exp"]).default("linear"),
});

const router = Router();

router.get("/", async (_req, res) => {
  const areas = await prisma.area.findMany({ where: { userId: DEFAULT_USER_ID } });
  res.json(areas);
});

router.get("/:id", async (req, res) => {
  const area = await prisma.area.findUnique({ where: { id: req.params.id } });
  if (!area) return res.status(404).json({ message: "Area not found" });
  res.json(area);
});

router.post("/", async (req, res) => {
  const parsed = areaSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  const area = await prisma.area.create({ data: { ...parsed.data, userId: DEFAULT_USER_ID } });
  res.status(201).json(area);
});

router.put("/:id", async (req, res) => {
  const parsed = areaSchema.partial().safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  try {
    const area = await prisma.area.update({ where: { id: req.params.id }, data: parsed.data });
    res.json(area);
  } catch {
    res.status(404).json({ message: "Area not found" });
  }
});

router.delete("/:id", async (req, res) => {
  try {
    await prisma.area.delete({ where: { id: req.params.id } });
    res.status(204).end();
  } catch {
    res.status(404).json({ message: "Area not found" });
  }
});

export default router;
