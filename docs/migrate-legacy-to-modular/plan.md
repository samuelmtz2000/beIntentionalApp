# Migration Plan: Legacy HabitsView → Modular Flow

Scope
- Replace legacy `HabitsView` with refactored, modular `HabitsViewRefactored`.
- Preserve UX parity: swipe actions, toasts, recovery gating, add/edit sheets.
- Ensure per-habit streak chips and history are present in modular rows.

Current State
- Active: `ContentView/MainTabView` → `HabitsView` (legacy).
- Modular (available but unused by default): `HabitsViewRefactored` → `NavigationHeaderContainer` + `HabitsListView` → `GoodHabitRow`/`BadHabitRow` → `StreakChip`, `StreakDots`, `HabitHistorySheet`.
- Backend streak endpoints live at `/streaks/*` and are consumed by `StreaksViewModel`.

Parity Checklist
- Header
  - General streak in `PlayerHeader` with celebration on success.
  - Legacy header badges/stats accounted for.
- Good habits
  - Swipe: Complete, Edit, Delete.
  - Row: name, XP/coins, streak chip, 7-day dots, tap → history sheet.
- Bad habits
  - Swipe: Record, Edit, Delete; recovery gating enforced.
  - Row: name, penalty, streak chip, 7-day dots, tap → history sheet.
- Add flows
  - New Good/Bad/Area sheets work; state refresh after save/delete.
- Toasts
  - Success toast on complete; warning toast on record; recovery messages.

Steps
1) Port swipe actions to modular rows
- Add `.swipeActions` to `GoodHabitRow` and `BadHabitRow` (or parent list) replicating legacy behavior.
- Wire callbacks via closures to the host `HabitsViewRefactored` coordinator.

2) Verify recovery gating
- When `game.state != .active`, bad-habit record should open recovery flow.
- Add conditional guard in modular action callbacks.

3) Wire toasts and refresh
- On success/warn, trigger the same toast messages via a shared `ToastView` or coordinator.
- Refresh view models on action completion.

4) Switch MainTabView
- Change `ContentView/MainTabView` from `HabitsView()` to `HabitsViewRefactored()`.
- Smoke test: header streak, list rows, actions, sheets, toasts.

5) Clean up legacy
- Keep `HabitsView` as a thin wrapper temporarily or archive it.
- Update docs to make `HabitsViewRefactored` the canonical flow.

Risks & Rollback
- If parity gaps appear, revert `MainTabView` to `HabitsView` while patching.
- Keep migration localized; avoid changing unrelated screens.

Notes
- API query building bug fixed in `APIClient` so streak endpoints work reliably.
- All new/changed endpoints must be reflected in `apps/api/src/openapi.ts`.
