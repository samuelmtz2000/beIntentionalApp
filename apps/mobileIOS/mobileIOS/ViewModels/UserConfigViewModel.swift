import Foundation
import Combine

@MainActor
final class UserConfigViewModel: ObservableObject {
    @Published var xpPerLevel: Int = 100
    @Published var levelCurve: String = "linear"
    @Published var levelMultiplier: Double = 1.5
    @Published var xpComputationMode: String = "logs"
    @Published var isSaving = false
    @Published var isLoading = false
    @Published var apiError: APIError?

    private let api: APIClient
    private let userId: String

    init(api: APIClient, userId: String = "seed-user-1") {
        self.api = api
        self.userId = userId
    }

    struct ConfigBody: Codable {
        let xpPerLevel: Int
        let levelCurve: String
        let levelMultiplier: Double
        let xpComputationMode: String
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let cfg: ConfigBody = try await api.get("users/\(userId)/config")
            xpPerLevel = cfg.xpPerLevel
            levelCurve = cfg.levelCurve
            levelMultiplier = cfg.levelMultiplier
            xpComputationMode = cfg.xpComputationMode
        } catch let e as APIError { apiError = e }
        catch { apiError = APIError(message: error.localizedDescription) }
    }

    func save() async -> Bool {
        isSaving = true
        defer { isSaving = false }
        do {
            let body = ConfigBody(xpPerLevel: max(10, xpPerLevel), levelCurve: levelCurve, levelMultiplier: max(1.0, levelMultiplier), xpComputationMode: xpComputationMode)
            struct Ok: Codable { let ok: Bool }
            _ = try await api.put("users/\(userId)/config", body: body) as Ok
            return true
        } catch let e as APIError { apiError = e; return false }
        catch { apiError = APIError(message: error.localizedDescription); return false }
    }
}

