# Habit Hero Monorepo

Gamified habit manager that turns personal growth into an RPG. Monorepo managed by pnpm with an Express + Prisma API and an Expo + React Native mobile app.

## Packages

- `apps/api` — Express 5 + TypeScript + Prisma (SQLite), Zod validation, Swagger UI at `/docs`.
- `apps/mobile` — Expo + React Native + Expo Router, React Query, Zustand.

## Quick Start

Prereqs: Node 18+ (or 20+), pnpm.

1) Install deps
- pnpm install

2) Database (SQLite)
- pnpm db:migrate
- pnpm db:seed

3) Run
- API: pnpm dev:api (http://localhost:4000, docs at /docs)
- Mobile: pnpm dev:mobile (Expo dev server)

## Scripts (root)

- `dev:api` — start API in dev
- `dev:mobile` — start Expo dev server
- `db:migrate` — Prisma migrate dev
- `db:seed` — seed demo data for API
- `lint` — run ESLint
- `format` — run Prettier
- `test` — run API tests (Vitest)

## Environment

- API loads env via `dotenv`. Create `apps/api/.env`:
  - `PORT=4000`
- SQLite file lives at `apps/api/prisma/dev.db`.

## API

- Docs: Swagger UI at `http://localhost:4000/docs`
- Health: `GET /health` → `{ ok: true }`
- Full API docs and examples: `apps/api/README.md`

Key behavior
- Completing a good habit: adds XP to its area and rewards coins.
- Recording a bad habit: decreases life unless controllable and paid with coins.
- Areas level up based on configurable XP curves.
- Store supports cosmetic purchases; logs track actions and transactions.

## Mobile

- Expo Router tabs: Dashboard, Habits, Bad Habits, Store, Avatar.
- React Query for server state, Zustand for light UI prefs.
- To point to a non-default API URL, set `EXPO_PUBLIC_API_URL` in `apps/mobile/app.config.js` (optional in v1).

## Acceptance Checklist

1. `pnpm db:migrate && pnpm db:seed && pnpm dev:api` → `/health` returns `{ ok: true }`.
2. `pnpm dev:mobile` → Dashboard shows Life=100, Coins=0, Areas level 1.
3. Habits: "I did it" increases coins and area progress; Dashboard updates.
4. Bad Habits: "I slipped" reduces Life. If controllable + pay, Life doesn’t drop and Coins decrease.
5. Store: buying a cosmetic reduces Coins and shows as owned on Avatar.
6. No runtime TS errors; basic level-up animation plays.

## Contributing

- TypeScript strict; ESM everywhere.
- Run formatting and lint before pushing:
  - `pnpm dlx prettier -w . && pnpm dlx eslint . --ext .ts,.tsx`
- Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`, `test:`, etc.

## License

Proprietary (do not distribute). Contact the author for usage.
