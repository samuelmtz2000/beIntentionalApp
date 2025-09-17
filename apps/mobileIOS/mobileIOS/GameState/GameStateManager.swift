import Foundation
import Combine

@MainActor
final class GameStateManager: ObservableObject {
    @Published var state: GameState = .active
    @Published var health: Int = 1000
    @Published var gameOverAt: Date? = nil
    @Published var recoveryDistance: Int = 0
    @Published var recoveryTarget: Int = 42195
    @Published var recoveryPercentage: Int = 0

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func loadCached() {
        if let raw = UserDefaults.standard.string(forKey: "GAME_STATE"), let s = GameState(rawValue: raw) {
            state = s
        }
        if let d = UserDefaults.standard.object(forKey: "GAME_OVER_AT") as? Date { gameOverAt = d }
        recoveryDistance = UserDefaults.standard.integer(forKey: "RECOVERY_DISTANCE")
        let target = UserDefaults.standard.integer(forKey: "RECOVERY_TARGET")
        recoveryTarget = target > 0 ? target : 42195
        recoveryPercentage = UserDefaults.standard.integer(forKey: "RECOVERY_PCT")
        health = max(0, UserDefaults.standard.integer(forKey: "HEALTH"))
    }

    private func persist() {
        UserDefaults.standard.set(state.rawValue, forKey: "GAME_STATE")
        UserDefaults.standard.set(gameOverAt, forKey: "GAME_OVER_AT")
        UserDefaults.standard.set(recoveryDistance, forKey: "RECOVERY_DISTANCE")
        UserDefaults.standard.set(recoveryTarget, forKey: "RECOVERY_TARGET")
        UserDefaults.standard.set(recoveryPercentage, forKey: "RECOVERY_PCT")
        UserDefaults.standard.set(health, forKey: "HEALTH")
    }

    func refreshFromServer() async {
        // Endpoint path to be aligned with backend; using placeholder until wired.
        struct Dummy: Decodable {}
        _ = Dummy.self
        // No-op for now; wiring will be added during integration phase.
    }

    func updateFrom(info: GameStateInfo) {
        state = info.state
        health = info.health
        gameOverAt = info.gameOverDate
        recoveryDistance = info.recoveryDistance ?? 0
        recoveryTarget = info.recoveryTarget ?? 42195
        recoveryPercentage = info.recoveryPercentage ?? 0
        persist()
    }
}

