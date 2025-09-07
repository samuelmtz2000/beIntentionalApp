---
title: Actions
---

Complete habit
- POST `/actions/habits/:id/complete`
  - Upserts AreaLevel, applies XP via level curve, increments coins, writes logs.
  - Response: `{ areaLevel, user: { coins } }`.

Record bad habit
- POST `/actions/bad-habits/:id/record`
  - If a credit exists for this bad habit (see Store), consume 1 and avoid life loss.
  - Else, decrement life by the habit’s `lifePenalty`.
  - Always writes `BadHabitLog` with `avoidedPenalty`.
  - Response: `{ user: { life }, avoidedPenalty }`.

