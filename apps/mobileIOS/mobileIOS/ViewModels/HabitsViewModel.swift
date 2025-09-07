import Foundation
import Combine

@MainActor
final class HabitsViewModel: ObservableObject {
    @Published var habits: [GoodHabit] = []
    @Published var isLoading = false
    @Published var apiError: APIError?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            habits = try await api.get("habits")
        } catch let e as APIError {
            apiError = e
        } catch {
            apiError = APIError(message: error.localizedDescription)
        }
    }

    func create(areaId: String, name: String, xpReward: Int, coinReward: Int, cadence: String?, isActive: Bool) async {
        struct Body: Encodable { let areaId, name: String; let xpReward, coinReward: Int; let cadence: String?; let isActive: Bool }
        isLoading = true
        defer { isLoading = false }
        do {
            let habit: GoodHabit = try await api.post("habits", body: Body(areaId: areaId, name: name, xpReward: xpReward, coinReward: coinReward, cadence: cadence, isActive: isActive))
            habits.append(habit)
        } catch let e as APIError { apiError = e } catch { apiError = APIError(message: error.localizedDescription) }
    }

    func update(habit: GoodHabit) async {
        struct Body: Encodable { let areaId, name: String; let xpReward, coinReward: Int; let cadence: String?; let isActive: Bool }
        do {
            let updated: GoodHabit = try await api.put("habits/\(habit.id)", body: Body(areaId: habit.areaId, name: habit.name, xpReward: habit.xpReward, coinReward: habit.coinReward, cadence: habit.cadence, isActive: habit.isActive))
            if let idx = habits.firstIndex(where: { $0.id == updated.id }) { habits[idx] = updated }
        } catch let e as APIError { apiError = e } catch { apiError = APIError(message: error.localizedDescription) }
    }

    func delete(id: String) async {
        do {
            try await api.delete("habits/\(id)")
            habits.removeAll { $0.id == id }
        } catch let e as APIError { apiError = e } catch { apiError = APIError(message: error.localizedDescription) }
    }

    func complete(id: String) async -> CompleteHabitResponse? {
        struct Empty: Encodable {}
        do {
            let resp: CompleteHabitResponse = try await api.post("actions/habits/\(id)/complete", body: Empty())
            return resp
        } catch let e as APIError { error = e } catch { error = APIError(message: error.localizedDescription) }
        return nil
    }
}
