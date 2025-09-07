# Habit Hero API

Express + TypeScript + Prisma (SQLite). Strict ESM, Zod‑validated routes. Ships a built‑in Swagger UI tester at `/docs` and a lightweight HTML tester at `/tester` (dev helper).

## Quick Start

- Install deps: `pnpm -F @habit-hero/api install`
- Migrate DB: `pnpm db:migrate`
- Seed demo data: `pnpm db:seed`
- Run dev server: `pnpm dev:api` (opens `http://localhost:4000/docs`)
- Health check: `GET /health` → `{ ok: true }`

## Environment

- Env loader: `dotenv`
- Create `apps/api/.env` (example):
  - `PORT=4000`
- SQLite file: `apps/api/prisma/dev.db`

## Scripts (from repo root)

- `pnpm dev:api` — start API on `:4000` (or `PORT`)
- `pnpm db:migrate` — run Prisma migrations
- `pnpm db:seed` — seed demo data
- `pnpm test` — run API tests (Vitest)

## Tech Stack

- Express 5 (ESM)
- Prisma ORM (`@prisma/client`) with SQLite
- Zod for input validation
- Security: `helmet`, `cors`, `express-rate-limit`
- Docs/Tester: `swagger-ui-express` at `/docs`

## Data Model (Prisma)

- User(id, name?, life=100, coins=0, avatar Json?)
- Area(id, userId, name, icon?, xpPerLevel=100, levelCurve="linear")
- GoodHabit(id, areaId, name, xpReward=10, coinReward=5, cadence?, isActive=true)
- BadHabit(id, areaId?, name, lifePenalty=5, controllable=false, coinCost=0, isActive=true)
- AreaLevel(id, userId, areaId, level=1, xp=0) with unique (userId, areaId)
- HabitLog(id, userId, habitId, timestamp)
- BadHabitLog(id, userId, badHabitId, timestamp, paidWithCoins)
- Transaction(id, userId, amount, type, meta?, timestamp)
- Cosmetic(id, category, key, price)
- UserCosmetic(id, userId, cosmeticId, ownedAt)

Default user for v1 (no auth): `seed-user-1`.

## API Overview

All bodies are JSON. Validation errors: HTTP 400 with Zod error details. Missing resources: HTTP 404.

- Health `/health`
  - GET → `{ ok: true }`

- Profile `/me`
  - GET → `{ life, coins, areas: [{ areaId, name, level, xp, xpPerLevel }], cosmeticsOwned: [...] }`

- Areas `/areas`
  - GET — list areas for default user
  - POST — create
    - Body: `{ name, icon?, xpPerLevel>=10, levelCurve: "linear"|"exp" }`
  - PUT `/:id` — update (partial)
  - DELETE `/:id` — delete

- Good Habits `/habits`
  - GET — list (includes `area` relation)
  - POST — create
    - Body: `{ areaId, name, xpReward>=1, coinReward>=0, cadence?, isActive }`
  - PUT `/:id` — update (partial)
  - DELETE `/:id` — delete

- Bad Habits `/bad-habits`
  - GET — list (includes `area` relation)
  - POST — create
    - Body: `{ areaId?, name, lifePenalty>=1, controllable, coinCost>=0, isActive }`
  - PUT `/:id` — update (partial)
  - DELETE `/:id` — delete

- Actions `/actions`
  - POST `/actions/habits/:id/complete`
    - Applies XP to the habit’s area, upserts AreaLevel for default user, increments user coins, creates `HabitLog` and `Transaction`.
    - Response: `{ areaLevel, user: { coins } }`
  - POST `/actions/bad-habits/:id/record` body `{ payWithCoins?: boolean }`
    - If controllable + payWithCoins + enough coins → deduct coins, add `Transaction`, `paidWithCoins=true`, no life loss.
    - Else reduce user `life` by `lifePenalty`.
    - Always creates `BadHabitLog`.
    - Response: `{ user: { life }, paidWithCoins }`

- Store `/store`
  - GET `/store/controlled-bad-habits` — list controllable bad habits
  - GET `/store/cosmetics` — list cosmetics
  - POST `/store/cosmetics/:id/buy` — buy cosmetic if enough coins; creates `UserCosmetic` and `Transaction`

- Docs `/docs`
  - Swagger UI interactive tester

- Dev Tester `/tester`
  - Lightweight HTML page with quick forms (dev convenience)

## Example Requests

- Create Area
```
curl -X POST http://localhost:4000/areas \
  -H 'Content-Type: application/json' \
  -d '{"name":"Wellness","icon":"💆","xpPerLevel":120,"levelCurve":"linear"}'
```

- Update Area
```
curl -X PUT http://localhost:4000/areas/area-health \
  -H 'Content-Type: application/json' \
  -d '{"name":"Health+","xpPerLevel":150}'
```

- Delete Area
```
curl -X DELETE http://localhost:4000/areas/area-learning
```

- Create Habit
```
curl -X POST http://localhost:4000/habits \
  -H 'Content-Type: application/json' \
  -d '{"areaId":"area-health","name":"Stretch 5m","xpReward":10,"coinReward":4,"cadence":"daily","isActive":true}'
```

- Update Habit
```
curl -X PUT http://localhost:4000/habits/habit-pushups \
  -H 'Content-Type: application/json' \
  -d '{"xpReward":12,"coinReward":6,"isActive":true}'
```

- Delete Habit
```
curl -X DELETE http://localhost:4000/habits/habit-reading
```

- Create Bad Habit
```
curl -X POST http://localhost:4000/bad-habits \
  -H 'Content-Type: application/json' \
  -d '{"areaId":"area-learning","name":"Doomscroll","lifePenalty":4,"controllable":true,"coinCost":3,"isActive":true}'
```

- Update Bad Habit
```
curl -X PUT http://localhost:4000/bad-habits/bad-doomscroll \
  -H 'Content-Type: application/json' \
  -d '{"coinCost":5,"controllable":true,"isActive":true}'
```

- Delete Bad Habit
```
curl -X DELETE http://localhost:4000/bad-habits/bad-junk-food
```

- Complete Habit
```
curl -X POST http://localhost:4000/actions/habits/habit-pushups/complete
```

- Record Bad Habit (pay with coins)
```
curl -X POST http://localhost:4000/actions/bad-habits/bad-doomscroll/record \
  -H 'Content-Type: application/json' \
  -d '{"payWithCoins":true}'
```

- Buy Cosmetic
```
curl -X POST http://localhost:4000/store/cosmetics/cos-badge-starter/buy
```

## Leveling Helpers

Shared logic in `src/lib/leveling.ts`:
- `xpForLevel(level, xpPerLevel, curve)`
- `applyHabitCompletion(currentXP, currentLevel, addXP, xpPerLevel, curve) -> { level, xp }`

## Seed Data

`pnpm db:seed` creates:
- User: `seed-user-1`
- Areas: `area-health`, `area-learning`, `area-finance`
- Habits: `habit-pushups`, `habit-reading`, `habit-budget`
- Bad Habits: `bad-junk-food`, `bad-doomscroll`
- Cosmetics: `cos-badge-starter`, `cos-badge-hero`

## Errors & Conventions

- JSON responses; validation errors → 400; not found → 404
- Rate limiting: default 120 req/min (adjust in `src/index.ts`)
- CORS enabled by default for local development

## Development Notes

- ESM everywhere; run via `node --import tsx/esm`
- TypeScript strict; lint/format from repo root:
  - `pnpm dlx prettier -w . && pnpm dlx eslint . --ext .ts,.tsx`
