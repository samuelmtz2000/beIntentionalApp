---
title: Design System
---

The iOS app uses a small but scalable Design System under `apps/mobileIOS/mobileIOS/DesignSystem` and `Shared/Components`.

Tokens & Foundations
- Colors: `DSTheme.colors(for:)` provides semantic colors for light/dark
- Typography: `dsFont(_:)` wrapper with a small type scale (`headerLG`, `headerMD`, `body`, `caption`)
- Spacing/Radii: lightweight constants for layout

Core Components
- Buttons: `PrimaryButtonStyle`, `SecondaryButtonStyle`, `DestructiveButtonStyle`, and wrapper `DSButton(title:icon:style:)`
- Cards: `cardStyle()` view modifier and `DSCard{}` container
- Navigation: `MainNavigationBar` (animated pills), `DSNavigationPill`
- Headers: `DSSectionHeader(title:icon:)`
- Forms: `DSFormField`, `DSPickerField`, `DSToggleField`
- Progress: `DSProgressBar(value:total:label:showPercentage:)`
- Empty State: `DSEmptyState(icon:title:message:actionTitle:action:)`

Sheets
- Use `DSSheet` for consistent Cancel/Save in the navigation bar, loading overlay, and validation summary.

Usage Example
```swift
DSCard {
  VStack(alignment: .leading) {
    Text("Push Ups").dsFont(.body)
    HStack(spacing: 8) {
      Label("+10 XP", systemImage: "star.fill").font(.caption)
      Label("+5", systemImage: "creditcard").font(.caption)
    }
    DSButton("I did it", icon: "checkmark") { /* action */ }
  }
}
```

Guidelines
- Prefer composition of DS components over ad-hoc styling
- Keep components small; add props only when repeated use-cases emerge
- Use semantic colors from `DSTheme` rather than hard-coded values

