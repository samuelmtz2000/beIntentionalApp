---
title: iOS Frontend Overview
---

Native SwiftUI app targeting iOS 17+. The app follows Apple and Swift API Design Guidelines and prefers clarity, value semantics, and testability.

Highlights
- Swift 5.9+, SwiftUI, MVVM, Combine where appropriate, async/await networking
- Clean layering: Views → ViewModels → Services → API Client
- Error handling with domain‑specific errors and user‑visible recovery
- Accessibility, performance, and offline resilience in scope

Modules
- Views: SwiftUI screens and reusable components
- ViewModels: state + side effects; expose `@MainActor` observable state
- Services: feature services (HabitsService, ProfileService)
- API Client: typed requests to backend (`/me`, `/habits`, actions, etc.)

Conventions
- Naming per Swift API Design Guidelines (clear, case‑correct, verb nouns)
- Doc comments `///` for public types; include usage examples
- Concurrency: `@MainActor` for UI; background work in services

Related
- See Configuration for base URL and environment settings
- See Testing for unit/UI testing guidelines

