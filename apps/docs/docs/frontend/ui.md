---
title: UI & Components
---

SwiftUI views are small, composable, and previewable. Emphasize accessibility and performance.

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

