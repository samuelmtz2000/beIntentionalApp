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
    private let userId: String

    init(api: APIClient, userId: String = "seed-user-1") {
        self.api = api
        self.userId = userId
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
        struct Response: Decodable {
            let state: GameState
            let health: Int
            let gameOverDate: Date?
            let recoveryStartedAt: Date?
            let recoveryDistance: Int?
            let recoveryTarget: Int?
            let recoveryPercentage: Int?
        }
        do {
            let info: Response = try await api.get("users/\(userId)/game-state")
            updateFrom(info: GameStateInfo(
                state: info.state,
                health: info.health,
                gameOverDate: info.gameOverDate,
                recoveryStartedAt: info.recoveryStartedAt,
                recoveryDistance: info.recoveryDistance,
                recoveryTarget: info.recoveryTarget,
                recoveryPercentage: info.recoveryPercentage
            ))
        } catch {
            // Keep local state if fetch fails
        }
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

    func setRecoveryProgress(meters: Int) {
        recoveryDistance = max(0, meters)
        let pct = Double(recoveryDistance) / Double(max(1, recoveryTarget))
        recoveryPercentage = min(100, Int(pct * 100.0))
        persist()
    }

    func refreshDistance(using healthKit: HealthKitService) async {
        guard let start = gameOverAt else { return }
        do {
            let meters = try await healthKit.distanceSince(date: start)
            setRecoveryProgress(meters: Int(meters))
        } catch {
            // Swallow errors here; UI can surface via toasts if desired
        }
    }

    func pushRecoveryProgress() async {
        struct Body: Encodable { let distance: Int }
        struct Resp: Decodable { let recoveryDistance: Int?; let recoveryPercentage: Int?; let remainingDistance: Int?; let isComplete: Bool? }
        do {
            let resp: Resp = try await api.put("users/\(userId)/recovery-progress", body: Body(distance: recoveryDistance))
            if let d = resp.recoveryDistance { recoveryDistance = d }
            if let p = resp.recoveryPercentage { recoveryPercentage = p }
            persist()
        } catch {
            // Ignore network errors for now
        }
    }

    func completeRecoveryIfEligible() async {
        guard recoveryDistance >= recoveryTarget else { return }
        struct Resp: Decodable { let gameState: GameState; let health: Int }
        do {
            let resp: Resp = try await api.post("users/\(userId)/complete-recovery", body: [String:Int]())
            state = resp.gameState
            health = resp.health
            gameOverAt = nil
            recoveryDistance = 0
            recoveryPercentage = 0
            persist()
        } catch {
            // ignore for now
        }
    }
}
