import Foundation

@MainActor
final class StoreViewModel: ObservableObject {
    @Published var controlledBadHabits: [BadHabit] = []
    @Published var ownedBadHabits: [OwnedBadHabit] = []
    @Published var coins: Int = 0
    @Published var isLoading = false
    @Published var apiError: APIError?

    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadControlledBadHabits() }
            group.addTask { await self.loadProfile() }
        }
    }

    private func loadControlledBadHabits() async {
        do { controlledBadHabits = try await api.get("bad-habits") }
        catch let e as APIError { apiError = e }
        catch let err { apiError = APIError(message: err.localizedDescription) }
    }

    private func loadProfile() async {
        do {
            let profile: Profile = try await api.get("me")
            self.coins = profile.coins
            self.ownedBadHabits = profile.ownedBadHabits ?? []
        } catch let e as APIError { apiError = e } catch let err { apiError = APIError(message: err.localizedDescription) }
    }

    func buy(cosmeticId: String) async {
        struct Empty: Encodable {}
        struct BuyResp: Decodable { let ok: Bool; let coins: Int }
        do {
            let resp: BuyResp = try await api.post("store/bad-habits/\(cosmeticId)/buy", body: Empty())
            self.coins = resp.coins
            await loadProfile()
        } catch let e as APIError { apiError = e } catch let err { apiError = APIError(message: err.localizedDescription) }
    }
}
