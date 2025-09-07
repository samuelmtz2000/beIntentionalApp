import Foundation

@MainActor
final class BadHabitsViewModel: ObservableObject {
    @Published var items: [BadHabit] = []
    @Published var isLoading = false
    @Published var apiError: APIError?

    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do { items = try await api.get("bad-habits") }
        catch let e as APIError { apiError = e }
        catch let err { apiError = APIError(message: err.localizedDescription) }
    }

    func create(areaId: String?, name: String, lifePenalty: Int, controllable: Bool, coinCost: Int, isActive: Bool) async {
        struct Body: Encodable { let areaId: String?; let name: String; let lifePenalty: Int; let controllable: Bool; let coinCost: Int; let isActive: Bool }
        do {
            let item: BadHabit = try await api.post("bad-habits", body: Body(areaId: areaId, name: name, lifePenalty: lifePenalty, controllable: controllable, coinCost: coinCost, isActive: isActive))
            items.append(item)
        } catch let e as APIError { apiError = e } catch let err { apiError = APIError(message: err.localizedDescription) }
    }

    func update(item: BadHabit) async {
        struct Body: Encodable { let areaId: String?; let name: String?; let lifePenalty: Int?; let controllable: Bool?; let coinCost: Int?; let isActive: Bool? }
        do {
            let updated: BadHabit = try await api.put("bad-habits/\(item.id)", body: Body(areaId: item.areaId, name: item.name, lifePenalty: item.lifePenalty, controllable: item.controllable, coinCost: item.coinCost, isActive: item.isActive))
            if let idx = items.firstIndex(where: { $0.id == updated.id }) { items[idx] = updated }
        } catch let e as APIError { apiError = e } catch let err { apiError = APIError(message: err.localizedDescription) }
    }

    func delete(id: String) async {
        do { try await api.delete("bad-habits/\(id)"); items.removeAll { $0.id == id } }
        catch let e as APIError { apiError = e }
        catch let err { apiError = APIError(message: err.localizedDescription) }
    }
}

