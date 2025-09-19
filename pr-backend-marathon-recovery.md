# Game Over & Marathon Recovery: Backend (schema, endpoints, triggers)

## Summary
This PR adds server-side support for the Game Over and Marathon Recovery system. It introduces schema fields, API endpoints to track recovery progress, and a trigger to enter game-over state when life reaches 0.

- Restores life to 1000 upon recovery completion
- Target distance: 42,195 meters

## Changes
- Prisma schema
  - User: `gameState`, `gameOverAt`, `recoveryStartedAt`, `recoveryDistance`, `recoveryCompletedAt`, `totalGameOvers`
  - Migration: `apps/api/prisma/migrations/20250915161500_add_game_over_recovery`
- Endpoints (`apps/api/src/router/users.ts`)
  - `GET /api/users/:id/game-state`
  - `PUT /api/users/:id/recovery-progress` (cumulative meters)
  - `POST /api/users/:id/complete-recovery` (restores life=1000, sets state=active)
- Actions (`apps/api/src/router/actions.ts`)
  - Trigger game over when life <= 0
  - Block habit actions when `gameState` != `active` (409)
- Docs (`apps/api/README.md`)
  - Documented new endpoints and behavior

## Testing
- Applied migrations and reseeded dev DB locally
- All API tests pass:
  - `health`, `user-config`, `area exp-leveling`, `global-level`

## Notes
- Kept existing "life" terminology in the app while aligning restore to 1000
- Anti-cheat validations for progress can be expanded in follow-ups

## Next Steps (follow-up PRs into this base branch)
- iOS scaffolding: GameState models/manager, HealthKitService, Game Over & Recovery UI
- Optional backend validations and analytics
