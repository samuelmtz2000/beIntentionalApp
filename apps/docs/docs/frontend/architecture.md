---
title: Architecture (MVVM)
---

The app uses MVVM with unidirectional data flow.

Folder structure (feature-first)
```
apps/mobileIOS/mobileIOS
├── Features/
│   ├── Player/{Views,ViewModels,Components}
│   ├── Habits/{Views,ViewModels,Components}
│   ├── Areas/{Views,ViewModels,Components}
│   ├── Store/{Views,ViewModels,Components}
│   └── Archive/{Views,ViewModels,Components}
├── Shared/{Components,Sheets,Extensions}
├── Core/{Storage,Networking,Models}
└── DesignSystem/*
```

Storage abstraction
- `Core/Storage/StorageProtocol.swift` defines a protocol for persistence (Profile, Areas, Habits, BadHabits)
- Default runtime impl is `APIStorage(api: APIClient)`, allowing future swap to SwiftData/GRDB/Realm
- `StorageManager` holds the active storage instance

Navigation and composition
- Use a lightweight coordinator per screen where helpful (e.g., `HabitsCoordinator`) to wire VMs and refresh logic
- Views bind to `@ObservedObject` VMs and compose small `Shared/` and `DesignSystem/` components

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

