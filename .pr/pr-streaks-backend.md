# feat(api): Streaks compute + endpoints; Swagger-only testing

Summary
- Implements Feature #6 (backend slice): general and per-habit streaks derived from existing logs.
- Standardizes manual API testing via Swagger UI at `/docs` and removes the custom `/tester` route.
- Adds OpenAPI entries for streaks endpoints to keep `/docs` accurate.

Changes
- API
  - New lib: `apps/api/src/lib/streaks.ts`
    - `computeGeneralStreak({ from, to, userId? })`
    - `computePerHabitStreaks({ from, to, userId? })`
    - `computeHabitHistory({ habitId, type, from, to, userId? })`
  - New routes: `apps/api/src/router/streaks.ts`
    - GET `/streaks/general?from&to`
    - GET `/streaks/habits?from&to`
    - GET `/streaks/habits/:id/history?type=good|bad&from&to`
  - Router mount: `apps/api/src/router/index.ts`
  - Swagger: `apps/api/src/openapi.ts` updated with the endpoints and response schemas.
  - Removed `/tester` (HTML): `apps/api/src/index.ts` now uses only `/docs` (Swagger UI).
- Tests
  - `apps/api/test/streaks-general.test.ts` (unforgiven vs forgiven behavior)
  - `apps/api/test/streaks-per-habit.test.ts` (history and aggregation)
- Docs
  - Agents: reference active feature and enforce OpenAPI updates (`agents/*.md`).
  - API README + Docusaurus docs switched to `/docs` and added OpenAPI maintenance note.
  - Feature docs: `docs/feature-06-streak/*` (summary, specs, roadmap).

Behavior Rules (confirmed)
- General streak day success: floor(80% of active good habits) AND no unforgiven bad logs. Zero active good habits + unforgiven bad = reset; zero active good + no unforgiven = freeze.
- Per-habit streaks:
  - Good: consecutive days with a log; miss resets; all days eligible until scheduling is formalized.
  - Bad: clean streak increments on days with no unforgiven occurrence; forgiven is neutral; any unforgiven resets.

Migration/Config
- No DB schema changes. Uses existing `HabitLog`, `BadHabitLog(avoidedPenalty)`, and `UserOwnedBadHabit`.

Validation
- Manual: `pnpm dev:api` and use Swagger at `http://localhost:4000/docs`.
- Automated: `pnpm -F @habit-hero/api test` (Vitest + Supertest).

Risks
- Denominator uses current active good habits; until we snapshot state per day, historical recalcs use current state (documented limitation).
- Timezone assumptions: grouped by server local day; per-user timezone can be added later.

Follow-ups
- iOS header streak and per-habit badges UI.
- Optional: add per-user timezone and formal scheduling to neutralize non-scheduled days.
- Extend OpenAPI with detailed models for other endpoints.

Base & Branch
- Base: `dev`
- Head: `feature/streaks-backend`
