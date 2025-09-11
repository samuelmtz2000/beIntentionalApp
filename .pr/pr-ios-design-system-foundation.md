Adds a first pass Design System foundation and a user-selectable theme switch (System/Light/Dark).

What & Why
- Introduces DSTheme with semantic colors, spacing, radii and simple components (PillButtonStyle, CardModifier) mapped to tokens from context/design-system.json.
- Adds Appearance picker in User Config, persisted to UserDefaults and applied app-wide via preferredColorScheme.
- Applies PillButtonStyle to TileNav chips for consistent look.

Files
- DesignSystem: apps/mobileIOS/mobileIOS/DesignSystem/{Color+Hex.swift, DesignSystem.swift}
- App: apps/mobileIOS/mobileIOS/mobileIOSApp.swift (appearance state + override)
- Config: apps/mobileIOS/mobileIOS/Views/UserConfigView.swift (Appearance section)
- Habits: apps/mobileIOS/mobileIOS/Views/HabitsView.swift (TileNav pill style)
- Context: context/design-system.json (tokens source)
- Agents docs linked for design review workflows

Test Plan
- Build & run on iPhone 15 + iPhone SE
- Open Config (gear) and toggle System/Light/Dark; UI updates immediately and persists
- Verify TileNav chips render with DS styling across sections (including Archive)
- Light/Dark pass on core screens; no functional regressions

Next Steps (follow-up PRs)
- Adopt DS spacing/colors/cards across Habits, Areas, Store, Archive
- Replace ad-hoc fonts with Dynamic Type text styles via DS wrappers
- Accessibility: hit targets ≥ 44×44, labels/traits, contrast sanity
- Orientation and empty/error states polish

