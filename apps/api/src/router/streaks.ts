import { Router } from "express";
import { computeGeneralStreak, computeHabitHistory, computePerHabitStreaks } from "../lib/streaks";

const router = Router();

// GET /streaks/general?from=YYYY-MM-DD&to=YYYY-MM-DD
router.get("/general", async (req, res) => {
  try {
    const today = new Date();
    const fmt = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
    const to = typeof req.query.to === "string" && req.query.to.length ? req.query.to : fmt(today);
    const from = typeof req.query.from === "string" && req.query.from.length
      ? req.query.from
      : fmt(new Date(today.getFullYear(), today.getMonth(), today.getDate() - 13)); // default: last 14 days

    const data = await computeGeneralStreak({ userId: (req as any).userId ?? undefined, from, to });
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ message: err?.message ?? "Failed to compute streak" });
  }
});

export default router;

// GET /streaks/habits?from&to
router.get("/habits", async (req, res) => {
  try {
    const today = new Date();
    const fmt = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
    const to = typeof req.query.to === "string" && req.query.to.length ? req.query.to : fmt(today);
    const from = typeof req.query.from === "string" && req.query.from.length
      ? req.query.from
      : fmt(new Date(today.getFullYear(), today.getMonth(), today.getDate() - 13));
    const data = await computePerHabitStreaks({ from, to });
    res.json({ items: data });
  } catch (err: any) {
    res.status(500).json({ message: err?.message ?? "Failed to compute habits streaks" });
  }
});

// GET /streaks/habits/:id/history?type=good|bad&from&to
router.get("/habits/:id/history", async (req, res) => {
  try {
    const type = req.query.type === "bad" ? "bad" : req.query.type === "good" ? "good" : null;
    if (!type) return res.status(400).json({ message: "type query must be 'good' or 'bad'" });
    const today = new Date();
    const fmt = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
    const to = typeof req.query.to === "string" && req.query.to.length ? req.query.to : fmt(today);
    const from = typeof req.query.from === "string" && req.query.from.length
      ? req.query.from
      : fmt(new Date(today.getFullYear(), today.getMonth(), today.getDate() - 6)); // default last 7 days
    const data = await computeHabitHistory({ habitId: req.params.id, type, from, to });
    res.json({ history: data });
  } catch (err: any) {
    res.status(500).json({ message: err?.message ?? "Failed to compute habit history" });
  }
});
