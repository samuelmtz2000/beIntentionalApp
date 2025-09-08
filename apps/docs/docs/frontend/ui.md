---
title: UI & Components
---

SwiftUI views are small, composable, and previewable. Emphasize accessibility and performance.

UI Navigation Patterns
- Tab navigation: Primary app sections are exposed via the bottom tab bar (Today, Habits, Settings, etc.). Screens should not hide the tab bar unless in a modal flow.
- Pill navigation: Within a screen (e.g., Habits), use horizontal “chips” (peels) to switch between local sections (Player / Habits / Areas / Store). The selected pill is filled (blue), others are neutral. A Config pill appears at the end to open the User Config sheet.
- Spotify‑like actions: Use swipe actions on list rows. Leading full swipe auto‑executes the primary action (Record). Trailing full swipe opens Edit; Delete is trailing and always asks for confirmation.
- Forms: Use native SwiftUI Forms. For Habits, Area is chosen via a Picker populated from the Areas catalog. Bad Habits allow “None (Global)”. Avoid manual ID entry.

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
