---
title: Models
---

Domain models mirror the API while remaining Swifty. Prefer value types, `Codable`, and clear naming.

```swift
struct Area: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let xpPerLevel: Int
    let levelCurve: String
}

struct GoodHabit: Codable, Identifiable, Equatable {
    let id: String
    let areaId: String
    let name: String
    let xpReward: Int
    let coinReward: Int
    let isActive: Bool
}

struct Profile: Codable, Equatable {
    let life: Int
    let coins: Int
    let areas: [AreaProgress]
}

struct AreaProgress: Codable, Identifiable, Equatable {
    let areaId: String
    let name: String
    let level: Int
    let xp: Int
    let xpPerLevel: Int

    var id: String { areaId }
    var progress: Double { Double(xp) / Double(max(1, xpPerLevel)) }
}
```

Mapping
- Keep DTOs separate if API naming diverges
- Compute presentation helpers (e.g., `progress`) outside networking layer

