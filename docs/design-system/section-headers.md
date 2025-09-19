# Section Headers — Design System Pattern

Purpose
- Provide a consistent, pinned section header for lists with optional leading icon and trailing action button.
- Ensure readability over scrolling content with an overlay background and bottom divider.

Component
- Use `DSSectionHeader(title:icon:trailingIcon:onTrailingTap:trailingColor:)` from `DesignSystem/DSComponents.swift`.
- Defaults: `dsFont(.headerMD)` for title, 18–20pt icon sizes, trailing button tinted with `accentSecondary`.
- Background: `backgroundSecondary` with a subtle bottom divider; behaves well when the header is pinned during scroll.

Usage
- Place inside `Section { ... } header: { ... }` in a `List`.
- Combine with `.listStyle(.plain)` and `.scrollContentBackground(.hidden)` on the list for clean visuals.
- For action buttons (e.g., add), pass `trailingIcon: "plus.circle.fill"` and `onTrailingTap: { ... }`.

Example
```
List {
  Section {
    // rows
  } header: {
    DSSectionHeader(
      title: "Areas",
      icon: "square.grid.2x2",
      trailingIcon: "plus.circle.fill",
      onTrailingTap: onAdd,
      trailingColor: .blue // match Habits
    )
  }
}
.listStyle(.plain)
.scrollContentBackground(.hidden)
```

Cards
- Use `DSCard { ... }` for list row containers to keep spacing and shape consistent.
- Titles use `dsFont(.body)`, secondary text uses `dsFont(.caption)` with `.foregroundStyle(.secondary)`.

Icons in Rows
- If using SF Symbols: `Image(systemName:)`.
- If using custom emojis or non-SF strings: render as `Text(...)` to avoid console errors like “No symbol named '💪' found in system symbol set”.
- Provide a default when missing (e.g., `"📦"`).

Color and Sizing
- Title: `dsFont(.headerMD)`.
- Leading icon: ~18pt.
- Trailing button: ~20pt, `accentSecondary` color.

Adoption
- Apply this pattern to all new list sections (Store, Archive, Areas, etc.) for consistent UX.
