# Running Challenge Feature — Requirements vs. Implementation

This document summarizes the requirements from the project docs and what has been implemented, including any additional work and what remains missing.

Sources reviewed
- docs/GAME_OVER_RECOVERY_SPEC.md (Game Over & Running Challenge System)
- docs/MARATHON_RECOVERY_ROADMAP.md (Running Challenge Recovery Roadmap)
- docs/PLANNING_SUMMARY.md (Planning Summary)
- pr-backend-marathon-recovery.md (original backend PR write-up)

## Requirements (from docs)
- Game state & health
  - States: active, game_over, recovery
  - New users start with 1000 life
  - Transition to game_over when life ≤ 0 during bad-habit record
- Game Over actions & UI
  - Record timestamp of game over (gameOverAt)
  - Show Game Over modal with challenge explanation
  - Disable bad-habit actions while not active
  - Present “Running Challenge” (dynamic target)
  - Header: skull icon in game_over; heart shows life/1000 otherwise
- Running Challenge (distance-based recovery)
  - Default target 42,195m; per-user configurable runningChallengeTarget
  - Valid activities: walking + running via HealthKit
  - Distance counts from gameOverAt (or recoveryStartedAt) until completion
  - Persist progress locally and sync with backend
  - Completion restores life to 1000 and returns to active
- iOS implementation
  - HealthKit permission + distance queries since start date
  - Modals and sheets for Game Over and Running Challenge
  - Progress UI with dynamic target, started date, and percentage
  - Completion flow
    - UI-first: show celebration (confetti) when target locally reached
    - On dismiss: finalize with backend and refresh UI
- Backend
  - User model fields: gameState, gameOverAt, recoveryStartedAt, recoveryDistance, recoveryCompletedAt, totalGameOvers, runningChallengeTarget
  - Endpoints
    - GET /users/:id/game-state → includes dynamic recovery_target
    - PUT /users/:id/recovery-progress → cumulative meters since start
    - POST /users/:id/complete-recovery → sets active, life=1000
  - Actions layer
    - Trigger game over on life ≤ 0
    - Block actions when not active (409)
- Docs & QA
  - Swagger/OpenAPI includes above endpoints
  - Tests for config + running challenge flow

## Implemented (accomplished)
- Backend
  - Added per-user runningChallengeTarget (default 42,195m) in schema and router usage
  - Implemented GET/PUT /users/:id/config to expose/edit target
  - GET /users/:id/game-state returns recovery_target from user config
  - PUT /users/:id/recovery-progress and POST /users/:id/complete-recovery use per-user target
  - Actions: record bad habit triggers game over at life ≤ 0; blocks actions when not active
  - Tests: added running-challenge.test; adjusted tests to avoid state interference; full suite passing
  - Swagger: OpenAPI updated; /docs lists config and running-challenge endpoints
- iOS
  - GameStateManager with cached state, refresh from server, dynamic target, and windowing from recoveryStartedAt/gameOverAt
  - Header UI: skull icon in game_over; heart shows /1000 otherwise
  - Game Over modal: dynamic target text (km); starts recovery
  - Running Challenge sheet: dynamic target km, progress bar, Started date, Enable Health Access, Update Progress
  - HealthKitService: requestAuthorization + distanceSince(start)
  - Behavior: only bad habits blocked when not active; good habits remain enabled
  - Foreground refresh: if in recovery and access configured, refresh distance and trigger UI-first completion if eligible
  - UI-first completion: confetti modal, then finalize with backend and refresh
  - Settings: Running Challenge target editable; saving refreshes game state so modals reflect new distance
- Docs (repo and site)
  - Updated specs and roadmap to “Running Challenge”; dynamic target; header behavior; UI-first completion
  - Docusaurus: new API page for Running Challenge; data model updated; frontend UI page updated; sidebar includes the new page

## Additional (beyond baseline)
- UI-first completion flow with confetti modal before server finalize
- Foreground trigger to detect local completion without user tapping
- Dynamic target refresh from both game-state and user config before showing modals/sheets
- Swagger UI and tests refined for new endpoints

## Missing / Follow-ups
- Database migration artifact for runningChallengeTarget
  - Schema updated and code uses fallback, but migration file/rollout is not included here
- Anti-cheat validations on backend
  - Daily caps, consistency checks, multi-day minimum (spec calls for these; not yet implemented)
- HealthKit background observation
  - Periodic observations/anchors not implemented; manual/foreground update only
- Manual entry fallback (with verification)
  - Spec mentions it; not implemented
- Milestone (25%/50%/75%) confetti
  - Only final completion confetti implemented
- Docs consistency
  - The original pr-backend-marathon-recovery.md references “marathon” and fixed 42,195m; superseded by “Running Challenge” and dynamic target in this branch

## Definition of Done (from docs) — Status
- Acceptance criteria met: largely yes (dynamic target, modals, progress, completion, state transitions)
- Code review: pending PR review
- Unit/integration tests: present and passing for API; iOS not unit-tested
- Documentation updated: yes (repo docs + docs site + Swagger)
- UI/UX review: pending design sign-off
- Performance/security/accessibility: not explicitly benchmarked; reasonable defaults in place
- Beta/feedback/release notes: not in this PR scope

---

PR: https://github.com/samuelmtz2000/beIntentionalApp/pull/27
Branch: feature/ios-game-over-presentation

