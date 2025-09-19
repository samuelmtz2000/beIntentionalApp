//
//  StreaksViewModel.swift
//  mobileIOS
//

import Foundation

@MainActor
final class StreaksViewModel: ObservableObject {
    struct GeneralDay: Decodable { let date: String; let completedGood: Int; let totalActiveGood: Int; let hasUnforgivenBad: Bool; let daySuccess: Bool? }
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
}

