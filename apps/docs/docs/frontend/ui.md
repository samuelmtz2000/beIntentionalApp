---
title: UI & Components
---

SwiftUI views are small, composable, and previewable. Emphasize accessibility and performance.

## UI Navigation Patterns

- **Tab Navigation**: Streamlined 2-tab interface (Habits, Settings) for primary app sections. The Today tab has been removed for simplified navigation.
- **Pill Navigation**: Within screens, use horizontal "chips" to switch between sub-sections (Player / Habits / Areas / Store / Archive). The selected pill is filled (blue), others are neutral. A Config pill opens the User Config sheet.
- **Swipe Actions**: Use swipe actions on list rows. Leading full swipe auto-executes the primary action (Record habit). Trailing swipe reveals Edit/Delete with confirmation prompts.
- **Toast Notifications**: Provide immediate feedback for user actions with top-sliding toast messages that auto-dismiss after 3 seconds.
- **Forms**: Use native SwiftUI Forms. Areas are selected via Picker from the Areas catalog. Bad Habits can be "None (Global)". Avoid manual ID entry.

## Toast Notification System

Toast messages provide immediate visual feedback for habit completions:

```swift
// Usage example
@State private var toast: ToastMessage? = nil

// Show success toast
toast = ToastMessage(message: "✅ Exercise completed! +10 XP, +5 coins", type: .success)

// Show error toast
toast = ToastMessage(message: "⚠️ Smoking recorded. -10 life", type: .error)

// Apply to view
YourView()
  .toast($toast)
```

Toast types:
- **Success** (green with checkmark): Good habit completions showing XP/coin rewards
- **Error** (red with exclamation): Bad habit records showing life penalties
- **Info** (blue with info icon): General informational messages

Habits Header (Global XP)
```swift
VStack(alignment: .leading) {
  Text("Lvl \(profile.level)")
    .bold()
    .padding(6)
    .background(Capsule().fill(Color.blue.opacity(0.15)))
  let need = xpNeeded(level: profile.level,
                      base: profile.xpPerLevel,
                      curve: profile.config?.levelCurve ?? "linear",
                      multiplier: profile.config?.levelMultiplier ?? 1.5)
  ProgressView(value: Double(profile.xp), total: Double(max(need,1))) {
    HStack(spacing: 6) {
      Text("XP to next")
      Image(systemName: "arrow.right")
      Text("\(profile.xp) from \(need)")
    }
    .font(.caption)
    .foregroundStyle(.secondary)
  }
}
```

Config Entry (pill in chip bar)
```swift
TileNav(selected: $selected, onConfig: { showingConfig = true })
  .sheet(isPresented: $showingConfig) { UserConfigSheet(onSaved: { Task { await profileVM.refresh() } }) }
```

Per‑Area Legend
```swift
ForEach(profile.areas, id: \.areaId) { a in
  // compute need for this level using area curve + multiplier
  let meta = areas.first(where: { $0.id == a.areaId })
  let curve = meta?.levelCurve ?? "linear"
  let mult = meta?.levelMultiplier ?? 1.5
  let need = xpForLevel(level: a.level, base: a.xpPerLevel, curve: curve, multiplier: mult)
  ProgressView(value: Double(a.xp), total: Double(max(need,1))) {
    HStack(spacing: 6) {
      Text("XP to next")
      Image(systemName: "arrow.right")
      Text("\\(a.xp) from \\(need)")
    }
    .font(.caption)
    .foregroundStyle(.secondary)
  }
}
```

Example List
```swift
import SwiftUI

struct HabitsView: View {
    @State private var model: HabitsViewModel

    init(model: HabitsViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        List(model.items) { habit in
            HStack {
                Text(habit.name)
                Spacer()
                Button("I did it") { Task { await model.completeHabit(id: habit.id) } }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Complete \(habit.name)")
            }
        }
        .overlay { if model.isLoading { ProgressView() } }
        .task { await model.load() }
        .navigationTitle("Habits")
    }
}
```

Guidelines
- Keep business logic out of views; delegate to view models
- Prefer `Task` for async actions; don’t block the main thread
- Add accessibility labels, traits, and dynamic type support
- Use instruments to spot excessive re‑renders
