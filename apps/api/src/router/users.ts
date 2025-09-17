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

// --- Game Over & Marathon Recovery Endpoints ---

const recoveryProgressSchema = z.object({
  distance: z.number().int().min(0), // meters, cumulative since gameOverAt
});

// GET /api/users/:id/game-state
router.get("/:id/game-state", async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.params.id } });
  if (!user) return res.status(404).json({ message: "User not found" });

  const target = 42195; // meters
  const percentage = Math.min(100, Math.floor(((user.recoveryDistance ?? 0) / target) * 100));

  res.json({
    state: user.gameState,
    life: user.life,
    game_over_date: user.gameOverAt,
    recovery_started_at: user.recoveryStartedAt,
    recovery_distance: user.recoveryDistance ?? 0,
    recovery_target: target,
    recovery_percentage: percentage,
  });
});

// PUT /api/users/:id/recovery-progress
router.put("/:id/recovery-progress", async (req, res) => {
  const parsed = recoveryProgressSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());

  const user = await prisma.user.findUnique({ where: { id: req.params.id } });
  if (!user) return res.status(404).json({ message: "User not found" });

  // Only allow progress when in game over or recovery state
  if (user.gameState !== "game_over" && user.gameState !== "recovery") {
    return res.status(409).json({ message: "Recovery not active" });
  }

  const current = user.recoveryDistance ?? 0;
  const next = parsed.data.distance;
  if (next < current) {
    return res.status(400).json({ message: "Distance must be cumulative and non-decreasing" });
  }

  // Move to recovery state upon first progress
  const becomingRecovery = user.gameState === "game_over";
  const now = new Date();
  const target = 42195;

  const updated = await prisma.user.update({
    where: { id: req.params.id },
    data: {
      recoveryDistance: next,
      recoveryStartedAt: user.recoveryStartedAt ?? now,
      gameState: becomingRecovery ? "recovery" : user.gameState,
    },
  });

  const remaining = Math.max(0, target - updated.recoveryDistance);
  const percentage = Math.min(100, Math.floor((updated.recoveryDistance / target) * 100));
  const isComplete = updated.recoveryDistance >= target;

  res.json({
    recovery_distance: updated.recoveryDistance,
    recovery_percentage: percentage,
    remaining_distance: remaining,
    is_complete: isComplete,
  });
});

// POST /api/users/:id/complete-recovery
router.post("/:id/complete-recovery", async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.params.id } });
  if (!user) return res.status(404).json({ message: "User not found" });

  const target = 42195;
  if (user.recoveryDistance < target) {
    return res.status(400).json({ message: "Recovery distance not yet complete" });
  }

  const updated = await prisma.user.update({
    where: { id: req.params.id },
    data: {
      gameState: "active",
      life: 1000, // restore to full life per spec
      recoveryCompletedAt: new Date(),
      // keep history fields; optionally clear recoveryDistance to 0
    },
  });

  res.json({
    game_state: updated.gameState,
    life: updated.life,
    recovery_completed_at: updated.recoveryCompletedAt,
    message: "Congratulations! Your life has been restored!",
  });
});

export default router;
