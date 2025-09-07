# Habit Hero Monorepo

Gamified habit manager that turns personal growth into an RPG. Monorepo managed by pnpm with an Express + Prisma API and a native iOS app (SwiftUI). A React Native app exists but is currently paused.

## Packages

- `apps/api` — Express 5 + TypeScript + Prisma (SQLite), Zod validation, Swagger UI at `/docs`.
- `apps/mobileIOS` — Native iOS app (SwiftUI, MVVM, async/await). Open `apps/mobileIOS/mobileIOS.xcodeproj` in Xcode 15+.
- `apps/mobile` — Expo + React Native (paused for now).

## Quick Start

Prereqs: Node 18+ (or 20+), pnpm.

1) Install deps
- pnpm install

2) Database (SQLite)
- pnpm db:migrate
- pnpm db:seed

3) Run
- API: pnpm dev:api (http://localhost:4000, docs at /docs)
- iOS: open `apps/mobileIOS/mobileIOS.xcodeproj` in Xcode, select an iOS 17+ simulator, Run.
- React Native (paused): pnpm dev:mobile (Expo dev server)

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
- Recording a bad habit: decreases life unless a credit is available for a controllable bad habit (inventory model).
- Areas level up based on configurable XP curves.
- Store: purchase credits for controllable bad habits; logs track actions and transactions.

## Mobile

Primary frontend is the iOS app in `apps/mobileIOS` (SwiftUI). Configure API Base URL in the app’s Settings tab (stored in `UserDefaults` as `API_BASE_URL`, default `http://localhost:4000`).

The React Native app in `apps/mobile` is paused; do not modify unless explicitly requested.

## Acceptance Checklist

1. `pnpm db:migrate && pnpm db:seed && pnpm dev:api` → `/health` returns `{ ok: true }`.
2. iOS app builds and runs in simulator → Dashboard shows Life=100, Coins=0, Areas level 1.
3. Habits: "I did it" increases coins and area progress; Dashboard updates.
4. Bad Habits: "I slipped" reduces Life. If controllable + pay, Life doesn’t drop and Coins decrease.
5. Store: buying a controllable bad habit credit reduces Coins and increments inventory; related screens reflect updated counts.
6. No runtime TS errors; basic level-up animation plays.

## Contributing

- TypeScript strict; ESM everywhere.
- Run formatting and lint before pushing:
  - `pnpm dlx prettier -w . && pnpm dlx eslint . --ext .ts,.tsx`
- Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`, `test:`, etc.

## License

Proprietary (do not distribute). Contact the author for usage.

## Agent Docs

- General agent instructions: `agents/agents.md`
- Habit Hero (iOS-first) agent guide: `agents/habit-hero-agent.md`
