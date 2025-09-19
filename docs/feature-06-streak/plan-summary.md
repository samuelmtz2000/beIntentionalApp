# Feature #6 — Streak Configuration (Data‑backed)

Goal

- Add a general daily streak in the header: increments on days where the user completes at least 80% of active good habits and records no unforgiven bad habits.
- Add per‑habit streaks: good habits show consecutive completion days; bad habits show consecutive clean days (no unforgiven occurrences).

Grounded in Current Data Model (Prisma)

- Good completions: `HabitLog(userId, habitId, timestamp)` — one row per completion.
- Bad occurrences: `BadHabitLog(userId, badHabitId, timestamp, avoidedPenalty)` — one row per event; `avoidedPenalty=true` means a store credit was consumed from `UserOwnedBadHabit` and penalty was avoided.
- Inventory/credits: `UserOwnedBadHabit(userId, badHabitId, purchasedAt)` — one row equals one credit; consumed by `/actions/bad-habits/:id/record`.
- Habits catalog: `GoodHabit(isActive, cadence?)`, `BadHabit(isActive)`.

Core Rules (Confirmed)

- Success threshold: floor(completed_good / total_active_good) >= 0.8.
- Bad habit rule: any `BadHabitLog` with `avoidedPenalty=false` for the day breaks the general streak and the corresponding bad‑habit clean streak.
- Zero good habits today: if there are zero active good habits AND there is any unforgiven bad habit today → reset general streak. If zero active good habits and no unforgiven bad → general streak does not change (freeze).
- Store‑bought forgiveness: means the bad habit occurrence was neutralized by consuming a purchased credit (inventory), represented by `BadHabitLog.avoidedPenalty=true`. Such logs do not break streaks.
- Grace period: users can backfill up to 24h; recalculations should update historical streaks accordingly.
- Rounding: threshold uses floor (e.g., 4/5 passes; 3/4 passes; 1/1 passes).

High‑Level UX

- Header flame with the general streak count; “celebration” animation when the day hits 80%+ and there are no unforgiven bad habits.
- Habit list badges:
  - Good: small flame + current streak; 7‑day mini‑calendar (completed, missed, inactive).
  - Bad: shield/ban + clean streak; 7‑day mini‑calendar (clean, forgiven, occurrence).
- “Forgive today” CTA after recording a bad habit if inventory is available; consuming a credit prevents streak break.

Roadmap (Phases)

1) Compute service (derive from logs) and API endpoints (hidden flag)
2) UI: header streak + list badges (without store UX)
3) Store credits UX wiring and forgiveness CTA
4) Telemetry, milestones, and nudges

