---
title: Architecture (MVVM)
---

The app uses MVVM with unidirectional data flow.

Layers
- Views (SwiftUI): render `@Observable` state and trigger intents
- ViewModels: translate intents to service calls; map domain → UI models
- Services: coordinate repositories/API; apply business logic
- API Client: HTTP transport and DTO ↔ domain mapping

Threading
- Annotate view models `@MainActor` to guarantee UI updates on the main thread
- Services perform async work; return results via `async` functions or `AsyncSequence`

Example ViewModel
```swift
import Foundation
import Observation

@MainActor
@Observable final class HabitsViewModel {
    private let habitsService: HabitsService

    var items: [HabitItem] = []
    var isLoading = false
    var error: String?

    init(habitsService: HabitsService) {
        self.habitsService = habitsService
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await habitsService.fetchHabits()
        } catch {
            self.error = Self.presentable(error)
        }
    }

    func completeHabit(id: String) async {
        do {
            try await habitsService.completeHabit(id: id)
            await load()
        } catch {
            self.error = Self.presentable(error)
        }
    }

    private static func presentable(_ error: Error) -> String { String(describing: error) }
}
```

