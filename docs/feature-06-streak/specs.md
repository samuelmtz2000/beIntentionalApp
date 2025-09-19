# Streak Specs — Based on Existing Log Tables

Scope

- Define algorithms, data derivations, and API shapes for general and per‑habit streaks using current tables: `HabitLog`, `BadHabitLog`, `GoodHabit`, `BadHabit`, `UserOwnedBadHabit`.

Day Boundary & Timezone

- Group by the user’s local day. Until a per‑user timezone exists server‑side, accept a `tz` or `date` range from clients, or compute on device for UI previews.

Denominators & Inputs

- Total active good habits (denominator): count `GoodHabit` where `isActive=true` and not soft‑deleted (same filter used by list endpoints). Cadence is currently free text; until scheduling is formalized, treat all active good habits as eligible daily.
- Completed good (numerator): count distinct `(habitId, date)` pairs in `HabitLog` for the day. If multiple logs exist for one habit on a day, dedupe to 1.
- Unforgiven bad flag: `exists BadHabitLog where avoidedPenalty=false for the day`.

General Streak Algorithm

- For date D:
  - totalActiveGood = count of active `GoodHabit` at D (exclude archived/soft‑deleted).
  - completedGood = count of distinct `HabitLog` entries for D (dedup per habitId).
  - hasUnforgivenBad = exists `BadHabitLog` for D with `avoidedPenalty=false`.
  - daySuccess = (totalActiveGood == 0)
      ? (!hasUnforgivenBad ? null : false) // freeze if no unforgiven bad, else failure
      : (floor(completedGood / totalActiveGood * 100) >= 80) && !hasUnforgivenBad.
  - Update:
    - If hasUnforgivenBad → reset to 0 (regardless of totalActiveGood).
    - Else if daySuccess == true and previous counted date is D‑1 → current++.
    - Else if daySuccess == true and gap → current=1.
    - Else if daySuccess == false → reset to 0.

Per‑Habit Streaks

- Good habit streak:
  - Consider active `GoodHabit` only.
  - For each day D: if there is at least one `HabitLog` for `(habitId, D)` → success; if none → miss; increment/reset across consecutive days accordingly.
  - Note: until cadence is formalized, treat every day as eligible; when a scheduling model exists, non‑scheduled days should be neutral.

- Bad habit clean streak:
  - For each day D: if any `BadHabitLog` exists with `avoidedPenalty=false` for that bad habit → reset to 0.
  - If there are only forgiven occurrences (`avoidedPenalty=true`) or no occurrences → increment by 1 from D‑1.

Forgiveness & Store‑Bought Credits

- Credits are rows in `UserOwnedBadHabit` and are consumed by `/actions/bad-habits/:id/record`.
- Consumption creates `BadHabitLog` with `avoidedPenalty=true`.
- Streak logic uses only `BadHabitLog.avoidedPenalty` to decide breaks: forgiven logs are neutral.

Grace Period & Backfill

- Allow backdating within 24 hours. Recompute streaks for affected date ranges upon late entries or corrections.

Edge Cases

- Zero active good habits:
  - If `hasUnforgivenBad=true` → reset.
  - Else → freeze (no increment or reset).
- Paused/archived habits: excluded from the denominator as soon as they are inactive/archived; historical days respect the habit’s state at that time if we snapshot, otherwise use current state and document the limitation.
- Multiple devices/offline: derive from authoritative logs; ensure idempotent writes for logs.

Suggested API Shapes (Server)

- GET `/streaks/general?from=YYYY-MM-DD&to=YYYY-MM-DD` →
  - { currentCount, longestCount, days: [ { date, completedGood, totalActiveGood, hasUnforgivenBad, daySuccess } ] }
- GET `/streaks/habits` → list of { habitId, type: "good"|"bad", currentCount, longestCount }
- GET `/streaks/habits/:id/history?days=30` → [ { date, status } ] where status ∈ good:{ done|miss|inactive } bad:{ clean|forgiven|occurred }

UI Contract

- Header shows the general streak and a progress meter for today `(completedGood / totalActiveGood)`. Trigger celebration animation immediately when reaching 80% with no unforgiven bad logged today.
- Habit cells show badges for per‑habit streaks and a 7‑day mini‑calendar using the statuses above.

Telemetry

- Track: dailySuccess, generalStreakLength, perHabitStreakLength, forgivenessUsage, atRiskDays.
- Milestones: 7, 30, 100 day streaks trigger celebrations.

