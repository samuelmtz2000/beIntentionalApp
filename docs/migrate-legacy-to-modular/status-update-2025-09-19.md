# Migration Status — 2025-09-19

**Current Status**
- Main tab now uses `HabitsViewRefactored`.
- Modular flow in place: header, habits list, areas, store, archive, config.
- Coordinator drives parallel refresh across Profile/Areas/Habits/BadHabits/Store/Archive.
- Toasts integrated for success/error across actions.

**Recent Advancements**
- Added recovery gating in bad-habit record flow tied to `game.state`, with Marathon Recovery sheet handoff and Health access prompts.
- Built Store and Archive list experiences with Design System cards, headers, swipe actions, and empty states.
- Implemented Player detail panel (stats card + per‑area progress) and Areas list with edit/delete flows.
- Unified add/edit sheets for Good/Bad/Area using shared sheet pattern; wired save/delete to refresh.

**Known Build Errors**
- apps/mobileIOS/mobileIOS/Views/HabitsViewRefactored.swift:201:13 Cannot find `StoreListView` in scope
- apps/mobileIOS/mobileIOS/Views/HabitsViewRefactored.swift:203:13 Cannot find `ArchiveListView` in scope

Notes:
- Both `StoreListView` and `ArchiveListView` are declared in the same file (lines ~441 and ~518 respectively). Investigation needed into scoping/brace placement or name collisions causing these to be unresolved at call site.

**Extras Beyond Original Plan**
- Player Stats Card + Area progress visuals (was not explicitly in the migration checklist).
- Concurrency: `withTaskGroup` for parallel view model refresh to reduce perceived latency.
- Fine‑grained toast copy for credit forgiveness vs. penalty on bad‑habit record.
- Store: “Owned (Credits)” section with counts; swipe‑to‑buy on controllable bad habits.
- Archive: Restore flows for Areas/Good/Bad with swipe actions and immediate refresh callback.

**What’s Missing From the Plan**
- Parity verification pass for all legacy swipe/toast flows (checklist items exist, final verification pending).
- Cleanup: legacy `HabitsView` still present; archival/thin wrapper step not done.
- Docs: make `HabitsViewRefactored` the canonical flow across docs/code comments.
- Tests: no unit tests for ViewModels or gating logic yet.
- Packaging: SPM modularization (DesignSystem/Core) still to do.

**Next Actions**
- Fix scope resolution for `StoreListView` and `ArchiveListView` in `HabitsViewRefactored.swift` (validate brace balance and file‑scope visibility; consider moving to separate files under Features/Store and Features/Archive).
- Run a parity sweep vs. legacy: swipes, toasts, recovery gating, add/edit sheets.
- Remove/rename legacy `HabitsView` after parity sign‑off; update references.
- Add lightweight tests for ViewModels (create/update/delete, record flows, recovery gating).
- Extract Store/Archive views to their feature folders to align with structure and avoid scope issues.

**Affected Files (key)**
- `apps/mobileIOS/mobileIOS/ContentView.swift` → switched to `HabitsViewRefactored()`.
- `apps/mobileIOS/mobileIOS/Views/HabitsViewRefactored.swift` → coordinator, navigation, list screens, sheets, toasts.
- `apps/mobileIOS/mobileIOS/Features/Habits/Views/HabitsListView.swift` → modular good/bad list rows.
- Design System components under `apps/mobileIOS/mobileIOS/DesignSystem` and `Shared/Components` used across new views.

**Open Questions**
- Should Player detail and area progress remain in Habits module or move under Player feature with a dedicated route?
- Confirm final copy for recovery gating toasts and Health access prompts.

