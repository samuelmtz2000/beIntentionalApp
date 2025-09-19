//
//  StreaksViewModel.swift
//  mobileIOS
//

import Foundation

@MainActor
final class StreaksViewModel: ObservableObject {
    struct GeneralDay: Decodable { let date: String; let completedGood: Int; let totalActiveGood: Int; let hasUnforgivenBad: Bool; let unforgivenBadCount: Int?; let daySuccess: Bool? }
    struct GeneralResponse: Decodable { let currentCount: Int; let longestCount: Int; let days: [GeneralDay] }
    struct HabitStreakItem: Decodable { let habitId: String; let type: String; let currentCount: Int; let longestCount: Int }
    struct HabitStreaksResponse: Decodable { let items: [HabitStreakItem] }
    struct HabitHistoryItem: Decodable { let date: String; let status: String }
    struct HabitHistoryResponse: Decodable { let history: [HabitHistoryItem] }

    private let api: APIClient
    @Published var generalToday: GeneralDay? = nil
    @Published var generalCurrent: Int = 0
    @Published var generalLongest: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var perHabit: [String: HabitStreakItem] = [:]
    @Published var goodHistory: [String: [HabitHistoryItem]] = [:] // habitId -> history (ordered)
    @Published var badHistory: [String: [HabitHistoryItem]] = [:]

    init(api: APIClient) { self.api = api }

    func refreshGeneralToday() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let today = Self.todayKey()
            let resp: GeneralResponse = try await api.get("streaks/general?from=\(today)&to=\(today)")
            generalCurrent = resp.currentCount
            generalLongest = resp.longestCount
            generalToday = resp.days.first
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    static func todayKey() -> String {
        let d = Date()
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.string(from: d)
    }

    func refreshPerHabit(days: Int = 14) async {
        do {
            let to = Self.todayKey()
            let from = Self.key(daysBefore: days - 1)
            let resp: HabitStreaksResponse = try await api.get("streaks/habits?from=\(from)&to=\(to)")
            var map: [String: HabitStreakItem] = [:]
            for it in resp.items { map[it.habitId] = it }
            self.perHabit = map
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func loadHistoryIfNeeded(habitId: String, type: String, days: Int = 7, force: Bool = false) async {
        if !force {
            if type == "good", goodHistory[habitId] != nil { return }
            if type == "bad", badHistory[habitId] != nil { return }
        }
        do {
            let to = Self.todayKey()
            let from = Self.key(daysBefore: days - 1)
            let resp: HabitHistoryResponse = try await api.get("streaks/habits/\(habitId)/history?type=\(type)&from=\(from)&to=\(to)")
            if type == "good" { goodHistory[habitId] = resp.history } else { badHistory[habitId] = resp.history }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    static func key(daysBefore: Int) -> String {
        let cal = Calendar.current
        let d = cal.date(byAdding: .day, value: -max(0, daysBefore), to: Date()) ?? Date()
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.string(from: d)
    }
}
