import Foundation

// Backend models (mirror API README)
struct Area: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    var name: String
    var icon: String?
    var xpPerLevel: Int
    var levelCurve: String
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

struct AreaLevel: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let areaId: String
    var level: Int
    var xp: Int
}

struct ProfileArea: Codable, Hashable { let areaId: String; let name: String; let level: Int; let xp: Int; let xpPerLevel: Int }
struct OwnedCosmetic: Codable, Hashable { let id: String; let category: String; let key: String }
struct Profile: Codable { let life: Int; let coins: Int; let areas: [ProfileArea]; let cosmeticsOwned: [OwnedCosmetic]? }

struct CompleteHabitResponse: Codable { let areaLevel: AreaLevel; let user: UserCoins }
struct UserCoins: Codable { let coins: Int }

struct BadHabit: Codable, Identifiable, Hashable {
    let id: String
    let areaId: String?
    var name: String
    var lifePenalty: Int
    var controllable: Bool
    var coinCost: Int
    var isActive: Bool
}

struct Cosmetic: Codable, Identifiable, Hashable {
    let id: String
    let category: String
    let key: String
    let price: Int
}
