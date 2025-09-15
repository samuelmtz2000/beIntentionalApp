//
//  StorageProtocol.swift
//  mobileIOS
//
//  Storage abstraction layer to support SwiftData (iOS 17+) or alternative storage solutions
//

import Foundation
import Combine

// MARK: - Storage Protocol

protocol StorageProtocol {
    // Profile operations
    func fetchProfile() async throws -> Profile?
    func updateProfile(_ profile: Profile) async throws
    
    // Area operations
    func fetchAreas(userId: String) async throws -> [Area]
    func saveArea(_ area: Area) async throws
    func updateArea(id: String, updates: AreaUpdates) async throws
    func deleteArea(id: String) async throws
    
    // Habit operations
    func fetchHabits(areaId: String?) async throws -> [GoodHabit]
    func saveHabit(_ habit: GoodHabit) async throws
    func updateHabit(id: String, updates: HabitUpdates) async throws
    func deleteHabit(id: String) async throws
    
    // Bad Habit operations
    func fetchBadHabits(areaId: String?) async throws -> [BadHabit]
    func saveBadHabit(_ habit: BadHabit) async throws
    func updateBadHabit(id: String, updates: BadHabitUpdates) async throws
    func deleteBadHabit(id: String) async throws
    
    // Clear all data
    func clearAllData() async throws
}

// MARK: - Update Models

struct ProfileUpdates {
    var life: Int?
    var coins: Int?
}

struct AreaUpdates {
    var name: String?
    var icon: String?
    var xpPerLevel: Int?
    var levelCurve: String?
    var levelMultiplier: Double?
}

struct HabitUpdates {
    var name: String?
    var xpReward: Int?
    var coinReward: Int?
    var cadence: String?
    var isActive: Bool?
}

struct BadHabitUpdates {
    var name: String?
    var lifePenalty: Int?
    var controllable: Bool?
    var coinCost: Int?
    var isActive: Bool?
}

// MARK: - Storage Error

enum StorageError: LocalizedError {
    case notFound
    case invalidData
    case migrationFailed
    case saveFailed(String)
    case fetchFailed(String)
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Data not found"
        case .invalidData:
            return "Invalid data format"
        case .migrationFailed:
            return "Database migration failed"
        case .saveFailed(let reason):
            return "Failed to save: \(reason)"
        case .fetchFailed(let reason):
            return "Failed to fetch: \(reason)"
        case .deleteFailed(let reason):
            return "Failed to delete: \(reason)"
        }
    }
}

// MARK: - Storage Manager

@MainActor
final class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    @Published private(set) var isReady = false
    private var storage: StorageProtocol
    
    private init() {
        // Default to API storage for now, can swap to SwiftData later
        // Note: APIClient needs to be provided via AppModel
        let baseURL = URL(string: UserDefaults.standard.string(forKey: "API_BASE_URL") ?? "http://localhost:4000")!
        self.storage = APIStorage(api: APIClient(baseURL: baseURL))
    }
    
    func configure(with storage: StorageProtocol) {
        self.storage = storage
        self.isReady = true
    }
    
    var currentStorage: StorageProtocol {
        storage
    }
}

// MARK: - API Storage Implementation (Current)

final class APIStorage: StorageProtocol {
    private let api: APIClient
    
    init(api: APIClient) {
        self.api = api
    }
    
    func fetchProfile() async throws -> Profile? {
        // Delegated to ProfileViewModel
        return nil
    }
    
    func updateProfile(_ profile: Profile) async throws {
        // Not implemented for API storage
        throw StorageError.saveFailed("Profile updates handled via specific API endpoints")
    }
    
    func fetchAreas(userId: String) async throws -> [Area] {
        // Delegated to AreasViewModel
        return []
    }
    
    func saveArea(_ area: Area) async throws {
        // Delegated to AreasViewModel
    }
    
    func updateArea(id: String, updates: AreaUpdates) async throws {
        // Delegated to AreasViewModel
    }
    
    func deleteArea(id: String) async throws {
        // Delegated to AreasViewModel
    }
    
    func fetchHabits(areaId: String?) async throws -> [GoodHabit] {
        // Delegated to HabitsViewModel
        return []
    }
    
    func saveHabit(_ habit: GoodHabit) async throws {
        // Delegated to HabitsViewModel
    }
    
    func updateHabit(id: String, updates: HabitUpdates) async throws {
        // Delegated to HabitsViewModel
    }
    
    func deleteHabit(id: String) async throws {
        // Delegated to HabitsViewModel
    }
    
    func fetchBadHabits(areaId: String?) async throws -> [BadHabit] {
        // Delegated to BadHabitsViewModel
        return []
    }
    
    func saveBadHabit(_ habit: BadHabit) async throws {
        // Delegated to BadHabitsViewModel
    }
    
    func updateBadHabit(id: String, updates: BadHabitUpdates) async throws {
        // Delegated to BadHabitsViewModel
    }
    
    func deleteBadHabit(id: String) async throws {
        // Delegated to BadHabitsViewModel
    }
    
    func clearAllData() async throws {
        // Not applicable for API storage
        throw StorageError.deleteFailed("Cannot clear API data from client")
    }
}
