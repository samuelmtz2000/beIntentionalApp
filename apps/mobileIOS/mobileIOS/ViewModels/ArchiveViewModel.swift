import Foundation

@MainActor
final class ArchiveViewModel: ObservableObject {
    @Published var areas: [Area] = []
    @Published var habits: [GoodHabit] = []
    @Published var badHabits: [BadHabit] = []
    @Published var isLoading = false
    @Published var apiError: APIError?

    private let api: APIClient

    init(api: APIClient) { self.api = api }

    struct ArchivePayload: Codable { let areas: [Area]; let habits: [GoodHabit]; let badHabits: [BadHabit] }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let resp: ArchivePayload = try await api.get("archive")
            self.areas = resp.areas
            self.habits = resp.habits
            self.badHabits = resp.badHabits
        } catch let e as APIError { apiError = e }
        catch let err { apiError = APIError(message: err.localizedDescription) }
    }

    func restoreArea(id: String) async {
        struct Empty: Encodable {}
        do { let _: Area = try await api.post("areas/\(id)/restore", body: Empty()) }
        catch let e as APIError { apiError = e } catch let err { apiError = APIError(message: err.localizedDescription) }
    }

    func restoreHabit(id: String) async {
        struct Empty: Encodable {}
        do { let _: GoodHabit = try await api.post("habits/\(id)/restore", body: Empty()) }
        catch let e as APIError { apiError = e } catch let err { apiError = APIError(message: err.localizedDescription) }
    }

    func restoreBadHabit(id: String) async {
        struct Empty: Encodable {}
        do { let _: BadHabit = try await api.post("bad-habits/\(id)/restore", body: Empty()) }
        catch let e as APIError { apiError = e } catch let err { apiError = APIError(message: err.localizedDescription) }
    }
}

