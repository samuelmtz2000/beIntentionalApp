---
title: Models
---

Domain models mirror the API while remaining Swifty. Prefer value types, `Codable`, and clear naming.

```swift
struct Area: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    var name: String
    var icon: String?
    var xpPerLevel: Int
    var levelCurve: String
    var levelMultiplier: Double?
}

struct GoodHabit: Codable, Identifiable, Hashable {
    let id: String
    let areaId: String
    var name: String
    var xpReward: Int
    var coinReward: Int
    var cadence: String?
    var isActive: Bool
}

struct BadHabit: Codable, Identifiable, Hashable {
    let id: String
    let areaId: String?
    var name: String
    var lifePenalty: Int
    var controllable: Bool
    var coinCost: Int
    var isActive: Bool
}

struct ProfileArea: Codable, Hashable {
    let areaId: String
    let name: String
    let level: Int
    let xp: Int
    let xpPerLevel: Int
}

struct Profile: Codable {
    let life: Int
    let coins: Int
    let level: Int
    let xp: Int
    let xpPerLevel: Int
    let config: ProfileConfig?
    let areas: [ProfileArea]
}
```

Notes
- `Profile.areas` are per-area progress snapshots (`ProfileArea`), not the core `Area` entities
- Use area metadata (curve/multiplier) from `Area` to compute per-area XP thresholds

Mapping
- Keep DTOs separate if API naming diverges
- Compute presentation helpers (e.g., `progress`) outside networking layer

