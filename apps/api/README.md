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

- User(id, name?, life=100, coins=0, avatar Json?, level=1, xp=0, xpPerLevel=100, levelCurve="linear", levelMultiplier=1.5, xpComputationMode="logs")
- Area(id, userId, name, icon?, xpPerLevel=100, levelCurve="linear", levelMultiplier=1.5)
- GoodHabit(id, areaId, name, xpReward=10, coinReward=5, cadence?, isActive=true)
- BadHabit(id, areaId?, name, lifePenalty=5, controllable=false, coinCost=0, isActive=true)
- AreaLevel(id, userId, areaId, level=1, xp=0) with unique (userId, areaId)
- HabitLog(id, userId, habitId, timestamp)
- BadHabitLog(id, userId, badHabitId, timestamp, avoidedPenalty)
- Transaction(id, userId, amount, type, meta?, timestamp)
- UserOwnedBadHabit(id, userId, badHabitId, purchasedAt)

Default user for v1 (no auth): `seed-user-1`.

## API Overview

All bodies are JSON. Validation errors: HTTP 400 with Zod error details. Missing resources: HTTP 404.

- Health `/health`
  - GET → `{ ok: true }`

- Profile `/me`
  - GET → returns global user stats and per‑area progress. Example:
  ```json
  {
    "life": 100,
    "coins": 12,
    "level": 2,
    "xp": 15,
    "xpPerLevel": 100,
    "config": { "levelCurve": "exp", "levelMultiplier": 1.5, "xpComputationMode": "logs" },
    "areas": [ { "areaId": "area-health", "name": "Health", "level": 1, "xp": 12, "xpPerLevel": 100 } ],
    "ownedBadHabits": [ { "id": "bad-doomscroll", "name": "Doomscrolling", "count": 2 } ]
  }
  ```

- Areas `/areas`
  - GET — list areas for default user
  - GET `/:id` — get by id
  - POST — create
    - Body: `{ name, icon?, xpPerLevel>=10, levelCurve: "linear"|"exp", levelMultiplier>=1? }`
  - PUT `/:id` — update (partial)
  - DELETE `/:id` — delete

- Good Habits `/habits`
  - GET — list (includes `area` relation)
  - GET `/:id` — get by id (includes `area`)
  - POST — create
    - Body: `{ areaId, name, xpReward>=1, coinReward>=0, cadence?, isActive }`
  - PUT `/:id` — update (partial)
  - DELETE `/:id` — delete

- Bad Habits `/bad-habits`
  - GET — list (includes `area` relation)
  - GET `/:id` — get by id (includes `area`)
  - POST — create
    - Body: `{ areaId?, name, lifePenalty>=1, controllable?, coinCost>=0, isActive }`
      - Note: `controllable` is ignored by the store logic; ALL bad habits can be purchased. `coinCost` is the purchase price for one credit.
  - PUT `/:id` — update (partial)
  - DELETE `/:id` — delete

- Actions `/actions`
  - POST `/actions/habits/:id/complete`
    - Applies XP to the habit’s area, upserts AreaLevel for default user, increments user coins, creates `HabitLog` and `Transaction`.
    - Global user XP/level behavior depends on `xpComputationMode`:
      - `logs` (default): user global XP/level are computed from history; stored counters are not updated on completion.
      - `stored`: user global XP/level counters are incremented on completion.
    - Response: `{ areaLevel, user: { coins, level?, xp?, xpPerLevel? } }`
  - POST `/actions/bad-habits/:id/record`
    - If the user has at least one purchased credit for that bad habit, one credit is consumed and the life penalty is avoided (applies to ALL bad habits).
    - Otherwise, reduce user `life` by `lifePenalty`.
    - Always creates `BadHabitLog` with `avoidedPenalty` flag.
    - Response: `{ user: { life }, avoidedPenalty }`

- Store `/store`
  - Listing: use `GET /bad-habits` directly (no separate store listing). The store UI should display all bad habits from `/bad-habits` with their `coinCost`.
  - Inventory: use `GET /me` and read `ownedBadHabits[{ id, name, count }]` to show how many pre‑paid credits the user has per bad habit.
  - POST `/store/bad-habits/:id/buy` — purchases one credit for that bad habit using `coinCost` (multiple purchases supported).

- Users `/users`
  - GET `/users/:id/config` → user leveling config
    - Response: `{ xpPerLevel, levelCurve, levelMultiplier, xpComputationMode }`
  - PUT `/users/:id/config` → update user leveling config
    - Body: `{ xpPerLevel>=10, levelCurve: "linear"|"exp", levelMultiplier>=1, xpComputationMode: "logs"|"stored" }`
    - Response: `{ ok: true, userId }`

- Docs `/docs`
  - Swagger UI interactive tester

- Dev Tester `/tester`
  - Lightweight HTML page with quick forms (dev convenience)

## Store Workflow (Frontend Notes)

- Discover
  - GET `/bad-habits` to list items (client can optionally filter to `controllable===true`).
  - GET `/me` to read `ownedBadHabits` inventory with counts.

- Purchase
  - POST `/store/bad-habits/:id/buy` purchases one credit (duplicates allowed). Price is `coinCost`.
  - Success: `{ ok: true, coins }` with updated coin balance.
  - Errors: `404` (invalid id), `400` (not purchasable or insufficient coins).
  - After purchase, refresh `/me` to reflect updated inventory counts and coins.

- Record behavior
  - POST `/actions/bad-habits/:id/record` checks inventory for controllable habits.
  - If `count > 0` → consume 1 credit and set `avoidedPenalty=true`.
  - Else (or if non‑controllable) → life decreases by `lifePenalty`.
  - Response: `{ user: { life }, avoidedPenalty }`.

- Admin/config
  - Update price: `PUT /bad-habits/:id` with new `coinCost` (visible immediately in the store list).
  - Toggle availability: set `isActive=false` to hide from the store.

- UI tips
  - Show a Buy button with a quantity selector; show available credits from `/me`.
  - On purchase, optimistically decrement coins or re‑fetch `/me` to stay authoritative.
  - On record, if credits are available, animate “Used 1 credit”; otherwise, show life decrease.

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

 - Record Bad Habit (consumes credit if owned)
```
curl -X POST http://localhost:4000/actions/bad-habits/bad-doomscroll/record
```

- Buy Controlled Bad Habit
```
curl -X POST http://localhost:4000/store/bad-habits/bad-doomscroll/buy
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
- (No cosmetics; purchase controllable bad habits instead)

## Errors & Conventions

- JSON responses; validation errors → 400; not found → 404
- Rate limiting: default 120 req/min (adjust in `src/index.ts`)
- CORS enabled by default for local development

## Development Notes

- ESM everywhere; run via `node --import tsx/esm`
- TypeScript strict; lint/format from repo root:
  - `pnpm dlx prettier -w . && pnpm dlx eslint . --ext .ts,.tsx`

## Global XP & Level

There are two modes for global user XP/Level:

- logs (default):
  - Global Level/XP are computed from history by summing `xpReward` for all `HabitLog`s and applying the configured curve.
  - Changing `xpPerLevel`, `levelCurve`, or `levelMultiplier` retroactively affects computed level.
- stored:
  - Global Level/XP are stored counters updated when a habit is completed.
  - Retrospective changes to the curve do not re‑compute historical XP.

### Curves

- linear: XP required per level is constant: `need(level) = xpPerLevel`.
- exp: XP grows with level via a multiplier: `need(level) = floor(xpPerLevel * levelMultiplier^(level-1))`.

Configure per‑user via `/users/:id/config`. Areas also support `levelCurve` and `levelMultiplier` for per‑area progression.
