# Repository Guidelines

## Project Structure & Module Organization

- Monorepo managed by `pnpm`. Workspace packages live under `apps/*`.
- API (`apps/api`): Express + TypeScript with Prisma (SQLite). Entry at `src/index.ts`; Prisma client in `src/lib/prisma.ts`; schema/migrations under `prisma/` (database at `apps/api/prisma/dev.db`).
- Mobile (`apps/mobile`): Expo + React Native with Expo Router. App screens live in `app/`; entry `index.ts`; assets in `assets/`.

## Build, Test, and Development Commands

- `pnpm dev:api` — start the API locally (defaults to `:4000`).
- `pnpm dev:mobile` — start the Expo dev server; or `pnpm -F @habit-hero/mobile ios|android|web` to target a platform.
- `pnpm db:migrate` — run Prisma migrations for the API (SQLite).
- `pnpm db:seed` — reserved for seeding; add `apps/api/prisma/seed.ts` before using.

## Coding Style & Naming Conventions

- Language: TypeScript (strict). Indentation: 2 spaces. Use ES modules.
- Tooling: ESLint (`eslint:recommended`) + Prettier. Run formatting before pushing.
  - Example: `pnpm dlx prettier -w . && pnpm dlx eslint . --ext .ts,.tsx`.
- Naming: camelCase for variables/functions; PascalCase for types/classes/React components.
  - API filenames: kebab-case (e.g., `routes/user-router.ts`).
  - Mobile components/screens: PascalCase files when exporting a component (e.g., `Profile.tsx`).

## Testing Guidelines

- No test runner is configured yet. For new features/bug fixes, include tests.
- Recommended stack: Vitest for API; Jest + React Native Testing Library for mobile.
- Place tests as `*.test.ts`/`*.test.tsx` next to code or under `__tests__/`.
- Target meaningful coverage on business logic; mock network/IO.

## Commit & Pull Request Guidelines

- Use Conventional Commits: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `test:`; include scope when helpful (e.g., `feat(api): ...`, `fix(mobile): ...`).
- Keep commits focused and incremental. Update migrations/docs when schema changes.
- PRs must include: concise description, linked issue, test plan/steps to reproduce, screenshots for UI changes, and notes on DB or config impacts.

## Security & Configuration Tips

- API loads env via `dotenv`. Create `apps/api/.env` (e.g., `PORT=4000`); never commit secrets.
- Manage DB via Prisma: update `schema.prisma`, run `pnpm db:migrate`, and verify the app `GET /health` before submitting changes.

# Functionality & App Objective

**Objective**  
Habit Hero is a gamified habit manager designed to make personal growth feel like playing an RPG. Users build positive habits (good habits) that act as _superpowers_, granting experience points (XP) and coins. At the same time, users track negative habits (bad habits), which drain their life unless “paid for” with earned coins. The app aims to encourage consistency, discipline, and balance by making progress visible and engaging.

**Core Functionalities**

- **Areas Management**
  - Users create _Areas_ (e.g., Health, Learning, Finance).
  - Each area holds its own habits and has its own level/XP progression.
  - Areas have configurable XP curves and per-level requirements.

- **Good Habits**
  - Each habit belongs to an area.
  - Completing a habit rewards XP (for the area) and coins (for the wallet).
  - Habits have configurable XP/coin rewards, cadence, and active status.
  - CRUD operations supported via API and mobile UI.

- **Bad Habits**
  - Bad habits can belong to an area or be global.
  - Logging a bad habit reduces life points.
  - Some bad habits are _controllable_—users can spend coins to avoid the life penalty (“pay to indulge”).
  - CRUD operations supported via API and mobile UI.

- **Levels & Progression**
  - Each area tracks user XP and level.
  - Level-ups occur when XP thresholds are crossed, with configurable curves (linear, exponential).
  - User can view overall progress across all areas.

- **Coins & Store**
  - Coins are earned through good habits.
  - Coins can be spent on:
    - Paying for controlled bad habits.
    - Purchasing cosmetics/character customizations.
  - Transactions are tracked for transparency.

- **Life System**
  - Users start with a set life total.
  - Logging unpaid bad habits decreases life.
  - The system motivates minimizing negative actions to preserve “HP.”

- **Character Customization**
  - Users can spend coins on cosmetics (avatars, outfits, badges).
  - Owned cosmetics are stored and selectable.

- **Logs & Tracking**
  - Habit logs: track completions.
  - Bad habit logs: track slips and whether coins were paid.
  - Transaction logs: track all coin gains/spends.

**Gameplay Loop**

1. Do a good habit → gain XP + coins → area level may increase.
2. Do a bad habit → lose life, unless paid with coins.
3. Spend coins in the store for cosmetics or to indulge controlled bad habits.
4. Progress areas and your avatar, reinforcing real-life discipline with game mechanics.

# Constraints & Stack (MUST)

- Monorepo with PNPM workspaces already created: `apps/api` (Express+Prisma+Zod+TS, SQLite) and `apps/mobile` (Expo+React Native+TS).
- Use existing choices:
  - **API**: Express, Prisma (SQLite), Zod, helmet, cors, express-rate-limit, dotenv.
  - **Mobile**: Expo Router, React Query, Zustand, Reanimated, FlashList, MMKV, SecureStore, Axios, date-fns.
- Keep TypeScript **strict**. ESM everywhere.

# High-Level Objective (from AGENTS.md)

- **Areas** contain Good Habits and Bad Habits.
- Completing a **Good Habit**: +XP to Area, +coins to wallet; configurable rewards per habit.
- **Bad Habit**: −Life unless it’s controllable and user **pays** coinCost to avoid penalty.
- **Area Leveling**: per-Area level & XP with configurable `xpPerLevel` and `levelCurve` (linear default).
- **Store**: buy controllable bad habits (pay at record time) and **Cosmetics** (avatar items).
- **Logs**: HabitLog, BadHabitLog, TransactionLog.
- **Character customization**: basic cosmetics ownership + selection (placeholder screen, functional purchase).

---

## 1) API: Implement full feature set

### 1.1 Prisma models

Use (or update to) this schema in `apps/api/prisma/schema.prisma`:

- `User(id, name?, life=100, coins=0, avatar Json?)`
- `Area(id, userId, name, icon?, xpPerLevel=100, levelCurve="linear")`
- `GoodHabit(id, areaId, name, xpReward=10, coinReward=5, cadence?, isActive=true)`
- `BadHabit(id, areaId?, name, lifePenalty=5, controllable=false, coinCost=0, isActive=true)`
- `AreaLevel(id, userId, areaId, level=1, xp=0)` with `@@unique([userId, areaId])`
- `HabitLog(id, userId, habitId, timestamp)`
- `BadHabitLog(id, userId, badHabitId, timestamp, paidWithCoins)`
- `Transaction(id, userId, amount, type, meta?, timestamp)`
- `Cosmetic(id, category, key, price)`
- `UserCosmetic(id, userId, cosmeticId, ownedAt)`

Run migration.

### 1.2 Shared server logic

Create `apps/api/src/lib/leveling.ts`:

- `xpForLevel(level, xpPerLevel, curve="linear")`
- `applyHabitCompletion(currentXP, currentLevel, addXP, xpPerLevel, curve) -> { level, xp }`

### 1.3 Routers (Zod-validated; use Prisma)

Create routers under `apps/api/src/router/` and mount in `src/index.ts`:

- **Areas** `/areas` (CRUD)
  - POST/PUT validate: `{ name, icon?, xpPerLevel>=10, levelCurve in ["linear","exp"] }`

- **Good Habits** `/habits` (CRUD)
  - Fields: `{ areaId, name, xpReward>=1, coinReward>=0, cadence?, isActive }`

- **Bad Habits** `/bad-habits` (CRUD)
  - Fields: `{ areaId?, name, lifePenalty>=1, controllable, coinCost>=0, isActive }`

- **Actions** `/actions`
  - `POST /actions/habits/:id/complete`
    - Finds habit + area, upserts AreaLevel for default user, applies XP, levels up if needed, increments coins by coinReward, writes `HabitLog` & `Transaction`.
    - Returns `{ areaLevel, user: { coins } }`.
  - `POST /actions/bad-habits/:id/record` body `{ payWithCoins?: boolean }`
    - If controllable & `payWithCoins` & sufficient coins → decrement coins by coinCost, record `Transaction`, set `paidWithCoins=true`, **no life loss**.
    - Else reduce `life` by `lifePenalty`.
    - Always write `BadHabitLog`.
    - Returns `{ user: { life }, paidWithCoins }`.

- **Store** `/store`
  - `GET /store/controlled-bad-habits` → list controllable bad habits.
  - `GET /store/cosmetics` → list all cosmetics.
  - `POST /store/cosmetics/:id/buy` → if enough coins, create `UserCosmetic`, decrement coins, add `Transaction`.

- **Profile** `/me`
  - Returns `{ life, coins, areas: [{ areaId, name, level, xp, xpPerLevel }], cosmeticsOwned: [...] }`.

- **Health** `/health` (already present).

**Assumptions**

- Use a single **DEFAULT_USER_ID** constant `"seed-user-1"` for v1 (no auth).
- Consistent error handling with 4xx on validation and 404 on resources.

### 1.4 Seed script

Create `apps/api/prisma/seed.ts`:

- Create default user `"seed-user-1"` with `life=100`, `coins=0`.
- Create Areas: Health, Learning, Finance (different `xpPerLevel` to demo).
- GoodHabits examples (pushups, reading, budgeting) with varied `xpReward/coinReward`.
- BadHabits examples (junk food, doomscrolling) including one `controllable=true, coinCost>0`.
- Add a couple of Cosmetics (e.g., `category:"badge"`, `key:"starter"`).
  Expose `pnpm db:seed`.

---

## 2) Mobile: Implement functional screens with live API

### 2.1 API client & query keys

- `apps/mobile/src/api/client.ts` with Axios `baseURL` = `http://localhost:4000`.
- `apps/mobile/src/api/keys.ts` with keys: `profile, areas, habits, badHabits, store, cosmetics, transactions`.

### 2.2 Navigation (Expo Router)

Create file-based routes under `apps/mobile/app/`:

- `_layout.tsx` with React Query provider and Tabs for:
  - `(tabs)/index.tsx` → **Dashboard**
  - `(tabs)/habits.tsx` → **Habits**
  - `(tabs)/bad-habits.tsx` → **Bad Habits**
  - `(tabs)/store.tsx` → **Store**
  - `(tabs)/avatar.tsx` → **Avatar**

### 2.3 Screens (initial, working UI)

- **Dashboard**
  - Fetch `/me` and display Life, Coins.
  - Show Areas with level + progress % (`xp / xpPerLevel`).
- **Habits**
  - List from `/habits` (FlashList).
  - Button “I did it” → `POST /actions/habits/:id/complete`, optimistic update coins/area progress, invalidate `profile`.
- **Bad Habits**
  - List from `/bad-habits`.
  - If `controllable`: two buttons:
    - “Pay {coinCost} coins” → record with `{payWithCoins:true}`.
    - “I slipped (no pay)” → `{payWithCoins:false}`.
  - If not controllable: single “I slipped”.
  - After mutation, invalidate `profile`.
- **Store**
  - Tabs/sections:
    - Controlled Bad Habits from `/store/controlled-bad-habits` (read-only).
    - Cosmetics from `/store/cosmetics`; Buy button triggers purchase and refreshes `profile`.
- **Avatar**
  - Show owned cosmetics from profile; allow selecting a current cosmetic (local placeholder state for v1).

### 2.4 State, storage, and animation

- Use **React Query** for server state; **Zustand** only for light UI prefs.
- Persist non-sensitive prefs in **MMKV**; secrets (none in v1) would go into **SecureStore**.
- Add a small **Reanimated** level-up animation (scale/opacity pop) after successful habit completion.

### 2.5 Components

Create minimal, reusable components under `apps/mobile/src/components/`:

- `LifeBar`, `CoinPill`, `AreaCard`, `ListItem` (pure components).
- Ensure FlashList `estimatedItemSize` set; keep items pure for perf.

---

## 3) Wiring, scripts, and DX

- Ensure `apps/api/src/index.ts` mounts all routers and uses helmet/cors/rate-limit.
- Root scripts work:
  - `pnpm dev:api` → starts API on `:4000`.
  - `pnpm db:migrate` → migrates SQLite.
  - `pnpm db:seed` → seeds demo data.
  - `pnpm dev:mobile` → starts Expo (Metro).
- Prettier/Eslint configs at repo root already exist; ensure no lint errors in generated code.

---

## 4) Manual acceptance checklist (must pass)

1. `pnpm db:migrate && pnpm db:seed && pnpm dev:api` starts server and `/health` returns `{ ok: true }`.
2. `pnpm dev:mobile` launches app; Dashboard shows Life=100, Coins=0, Areas with level 1.
3. In **Habits**, tapping “I did it” increases Coins and Area progress; Dashboard updates.
4. In **Bad Habits**, tapping “I slipped” (no pay) reduces Life; Dashboard updates. If controllable + “Pay …” pressed, Life does **not** drop and Coins decrease.
5. In **Store**, buying a cosmetic decreases Coins and shows as owned on **Avatar**.
6. No runtime TS errors; basic animations play on level-up.

---

## 5) Nice-to-have (if trivial)

- Add `/me` response types shared to the client via a small `types` file.
- Environment override for API base URL via `apps/mobile/app.config.js` (`EXPO_PUBLIC_API_URL`).

**Now implement all of the above, generating the necessary files and code in-place. Output only the file diffs (paths + contents) that you create or modify.**
