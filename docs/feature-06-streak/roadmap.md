# Streak Roadmap (No Dates)

Phase 1 — Compute & Derive

- Implement streak derivation functions from `HabitLog` and `BadHabitLog`.
- Add endpoints for general and per‑habit streaks (hidden or behind a flag).
- Unit tests: threshold rounding, freeze days, forgiveness neutrality, resets.

Phase 2 — Core UI

- Header: general streak with today’s progress and celebration when 80%+ with no unforgiven bad. Integrate into the refactored `NavigationHeaderContainer`/`PlayerHeader` as the canonical header.
- Habit list: per‑habit badges (good flame, bad shield) and 7‑day mini‑calendar markers.
- Empty states and at‑risk states (e.g., unforgiven bad recorded today).

Phase 3 — Store Integration

- Wire inventory to show available credits per bad habit.
- “Forgive today” CTA after recording occurrences; consume credit and update UI instantly.
- Edge handling: no credits, suggest navigating to Store.

Phase 4 — Reliability & Analytics

- Backfill within 24h; background recalculation for affected days.
- Telemetry, milestone celebrations, and nudges.
- Document timezone behavior and any known limitations until per‑user timezone lands.
