import Foundation

@MainActor
final class AreasViewModel: ObservableObject {
    @Published var areas: [Area] = []
    @Published var isLoading = false
    @Published var apiError: APIError?

    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do { areas = try await api.get("areas") }
        catch let e as APIError { apiError = e }
        catch let err { apiError = APIError(message: err.localizedDescription) }
    }

    func create(name: String, icon: String?, xpPerLevel: Int, levelCurve: String) async {
        struct Body: Encodable { let name: String; let icon: String?; let xpPerLevel: Int; let levelCurve: String }
        do {
            let area: Area = try await api.post("areas", body: Body(name: name, icon: icon, xpPerLevel: xpPerLevel, levelCurve: levelCurve))
            areas.append(area)
        } catch let e as APIError { apiError = e } catch let err { apiError = APIError(message: err.localizedDescription) }
    }

    func update(area: Area) async {
        struct Body: Encodable { let name: String?; let icon: String?; let xpPerLevel: Int?; let levelCurve: String? }
        do {
            let updated: Area = try await api.put("areas/\(area.id)", body: Body(name: area.name, icon: area.icon, xpPerLevel: area.xpPerLevel, levelCurve: area.levelCurve))
            if let idx = areas.firstIndex(where: { $0.id == updated.id }) { areas[idx] = updated }
        } catch let e as APIError { apiError = e } catch let err { apiError = APIError(message: err.localizedDescription) }
    }

    func delete(id: String) async {
        do { try await api.delete("areas/\(id)"); areas.removeAll { $0.id == id } }
        catch let e as APIError { apiError = e }
        catch let err { apiError = APIError(message: err.localizedDescription) }
    }
}

