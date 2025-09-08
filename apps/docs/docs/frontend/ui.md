---
title: UI & Components
---

SwiftUI views are small, composable, and previewable. Emphasize accessibility and performance.

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

Config Entry (gear icon)
```swift
.toolbar {
  ToolbarItem(placement: .navigationBarTrailing) {
    Button { showingConfig = true } label: { Image(systemName: "gearshape") }
  }
}
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
