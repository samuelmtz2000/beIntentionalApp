import { Router } from "express";
import { z } from "zod";
import prisma from "../lib/prisma";

const router = Router();

const configSchema = z.object({
  xpPerLevel: z.number().int().min(10),
  levelCurve: z.enum(["linear", "exp"]),
  levelMultiplier: z.number().min(1),
  xpComputationMode: z.enum(["stored", "logs"]),
});

router.get("/:id/config", async (req, res) => {
  const u = await prisma.user.findUnique({ where: { id: req.params.id } });
  if (!u) return res.status(404).json({ message: "User not found" });
  res.json({
    xpPerLevel: u.xpPerLevel,
    levelCurve: u.levelCurve,
    levelMultiplier: u.levelMultiplier,
    xpComputationMode: u.xpComputationMode,
  });
});

router.put("/:id/config", async (req, res) => {
  const parsed = configSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  try {
    const u = await prisma.user.update({
      where: { id: req.params.id },
      data: {
        xpPerLevel: parsed.data.xpPerLevel,
        levelCurve: parsed.data.levelCurve,
        levelMultiplier: parsed.data.levelMultiplier,
        xpComputationMode: parsed.data.xpComputationMode,
      },
    });
    res.json({ ok: true, userId: u.id });
  } catch {
    res.status(404).json({ message: "User not found" });
  }
});

export default router;

