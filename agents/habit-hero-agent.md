# Repository Guidelines

## Project Structure & Module Organization

- Monorepo managed by `pnpm`. Workspace packages live under `apps/*`.
- API (`apps/api`): Express + TypeScript with Prisma (SQLite). Entry at `src/index.ts`; Prisma client in `src/lib/prisma.ts`; schema/migrations under `prisma/` (database at `apps/api/prisma/dev.db`).
- Mobile (primary, "Mark" iOS app): Native iOS app in `apps/mobileIOS` (SwiftUI, MVVM). Xcode project at `apps/mobileIOS/mobileIOS.xcodeproj`.
- Mobile (React Native) in `apps/mobile` is currently paused. Do not modify unless explicitly requested.

## Build, Test, and Development Commands

- `pnpm dev:api` — start the API locally (defaults to `:4000`).
- React Native (paused): `pnpm dev:mobile` — Expo dev server; or `pnpm -F @habit-hero/mobile ios|android|web`.
- iOS native app: open `apps/mobileIOS/mobileIOS.xcodeproj` in Xcode 15+, select an iOS 17+ simulator, and Run.
- `pnpm db:migrate` — run Prisma migrations for the API (SQLite).
- `pnpm db:seed` — reserved for seeding; add `apps/api/prisma/seed.ts` before using.

## Coding Style & Naming Conventions

- Language: TypeScript (strict). Indentation: 2 spaces. Use ES modules.
- Tooling: ESLint (`eslint:recommended`) + Prettier. Run formatting before pushing.
  - Example: `pnpm dlx prettier -w . && pnpm dlx eslint . --ext .ts,.tsx`.
- Naming: camelCase for variables/functions; PascalCase for types/classes/React components.
  - API filenames: kebab-case (e.g., `routes/user-router.ts`).
  - iOS Swift: follow Swift API Design Guidelines; ViewModels suffix `ViewModel` (e.g., `HabitsViewModel`).
  - React Native (paused): components/screens PascalCase when exporting a component (e.g., `Profile.tsx`).

## Testing Guidelines

- No test runner is configured yet. For new features/bug fixes, include tests.
- Recommended stack: Vitest for API; Xcode unit/UI tests for iOS. RN tests optional while paused.
- Place tests as `*.test.ts`/`*.test.tsx` next to code or under `__tests__/`.
- Target meaningful coverage on business logic; mock network/IO.

## Commit & Pull Request Guidelines

- Use Conventional Commits: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `test:`; include scope when helpful (e.g., `feat(api): ...`, `fix(mobile): ...`).
- Keep commits focused and incremental. Update migrations/docs when schema changes.
- PRs must include: concise description, linked issue, test plan/steps to reproduce, screenshots for UI changes, and notes on DB or config impacts.

## Security & Configuration Tips

- API loads env via `dotenv`. Create `apps/api/.env` (e.g., `PORT=4000`); never commit secrets.
- Manage DB via Prisma: update `schema.prisma`, run `pnpm db:migrate`, and verify the app `GET /health` before submitting changes.
- iOS app base URL is configurable at runtime (Settings tab). Stored under `UserDefaults` key `API_BASE_URL`. Default `http://localhost:4000`.

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
  - Coins can be spent on purchasing credits for controllable bad habits (inventory model).
  - Recording a controllable bad habit consumes one credit if available; otherwise applies life penalty.
  - Transactions are tracked for transparency.

- **Life System**
  - Users start with a set life total.
  - Logging unpaid bad habits decreases life.
  - The system motivates minimizing negative actions to preserve “HP.”

- **Character Customization** (deferred)
  - Cosmetics are not implemented in the current iOS app/store model.
  - Future work may reintroduce cosmetics as separate purchasables.

- **Logs & Tracking**
  - Habit logs: track completions.
  - Bad habit logs: track slips and whether coins were paid.
  - Transaction logs: track all coin gains/spends.

**Gameplay Loop**

1. Do a good habit → gain XP + coins → area level may increase.
2. Do a bad habit → lose life, unless paid with coins.
3. Spend coins in the store to buy credits for controllable bad habits; recording with available credit avoids life loss.
4. Progress areas and your avatar, reinforcing real-life discipline with game mechanics.

# Constraints & Stack (MUST)

- Monorepo with PNPM workspaces already created: `apps/api` (Express+Prisma+Zod+TS, SQLite), `apps/mobileIOS` (SwiftUI native iOS), and `apps/mobile` (Expo+React Native, paused).
- Use existing choices:
  - **API**: Express, Prisma (SQLite), Zod, helmet, cors, express-rate-limit, dotenv.
  - **iOS Mobile**: Swift 5.9+, SwiftUI, MVVM, Combine, async/await, URLSession, Xcode 15+.
  - **React Native Mobile (paused)**: Expo Router, React Query, Zustand, Reanimated, FlashList, MMKV, SecureStore, Axios, date-fns.

# High-Level Objective (from AGENTS.md)

- **Areas** contain Good Habits and Bad Habits.
- Completing a **Good Habit**: +XP to Area, +coins to wallet; configurable rewards per habit.
- **Bad Habit**: −Life unless it’s controllable and user pays credit (inventory) to avoid penalty.
- **Area Leveling**: per-Area level & XP with configurable `xpPerLevel` and `levelCurve` (linear default).
- **Store**: buy credits for controllable bad habits (inventory). Cosmetics deferred.
- **Logs**: HabitLog, BadHabitLog, TransactionLog.
- **Character customization**: deferred.

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
  - `GET /store/controlled-bad-habits` → list controllable and active bad habits (price is `coinCost`).
  - `POST /store/bad-habits/:id/buy` → purchase one credit for a controllable bad habit; decrements coins; creates `Transaction`.

- **Profile** `/me`
  - Returns `{ life, coins, areas: [{ areaId, name, level, xp, xpPerLevel }], ownedBadHabits: [{ id, name, count }] }`.

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
- Cosmetics are deferred; seed creates default user, areas, and example good/bad habits only. Expose `pnpm db:seed`.

---

## 2) Mobile (iOS): Implement functional screens with live API

The actively developed frontend is the native iOS app in `apps/mobileIOS`.

Key screens (SwiftUI): Today, Habits, Settings.

Networking and models:
- `Networking/APIClient.swift` wraps URLSession with async/await.
- `Models/Models.swift` mirrors API contracts (Areas, Habits, BadHabits, AreaLevel, Profile, OwnedBadHabit, etc.).
- ViewModels orchestrate calls: `HabitsViewModel`, `BadHabitsViewModel`, `AreasViewModel`, `StoreViewModel`, `ProfileViewModel`.

Store and inventory:
- Use `POST /store/bad-habits/:id/buy` to purchase credits and `POST /actions/bad-habits/:id/record` to consume credits or apply penalties.
- Profile exposes `ownedBadHabits` counts for UI.

Note: The React Native app under `apps/mobile` is not being developed currently. Do not modify it unless specifically requested.

---

## 3) Wiring, scripts, and DX

- Ensure `apps/api/src/index.ts` mounts all routers and uses helmet/cors/rate-limit.
- Root scripts work:
  - `pnpm dev:api` → starts API on `:4000`.
  - `pnpm db:migrate` → migrates SQLite.
  - `pnpm db:seed` → seeds demo data.
  - iOS native app via Xcode; React Native via Expo only if resumed.
- Prettier/Eslint configs at repo root already exist; ensure no lint errors in generated code.

---

## 4) Manual acceptance checklist (must pass)

1. `pnpm db:migrate && pnpm db:seed && pnpm dev:api` starts server and `/health` returns `{ ok: true }`.
2. iOS app builds and runs in simulator; Dashboard shows Life=100, Coins=0, Areas with level 1.
3. In **Habits**, tapping “I did it” increases Coins and Area progress; Dashboard updates.
4. In **Bad Habits**, tapping “I slipped” (no pay) reduces Life; Dashboard updates. If controllable + “Pay …” pressed, Life does **not** drop and Coins decrease.
5. In **Store**, buying a controllable bad habit credit decreases Coins and increments inventory; related screens reflect updated counts.
6. No runtime TS errors; basic animations play on level-up.

---

## 5) Nice-to-have (if trivial)

- Add `/me` response types shared to the client via a small `types` file.
- iOS: base URL configurable in Settings (persisted in `UserDefaults`); optionally prefill via debug scheme.

---

Important: React Native app in `apps/mobile` is currently paused. Do not modify or refactor it unless there is an explicit task to do so. Focus frontend work on the native iOS app in `apps/mobileIOS`.

**Now implement all of the above, generating the necessary files and code in-place. Output only the file diffs (paths + contents) that you create or modify.**
