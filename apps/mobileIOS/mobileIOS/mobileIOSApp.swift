//
//  mobileIOSApp.swift
//  mobileIOS
//
//  Created by Samuel Martinez on 07/09/25.
//

import SwiftUI
import Combine

@main
struct HabitHeroApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appModel)
                .preferredColorScheme(appModel.colorSchemeOverride)
        }
    }
}

final class AppModel: ObservableObject {
    @Published var apiBaseURL: URL
    let api: APIClient
    let persistence: PersistenceController
    @Published var appearance: AppearancePreference

    init() {
        let base = URL(string: UserDefaults.standard.string(forKey: "API_BASE_URL") ?? "http://localhost:4000")!
        self.apiBaseURL = base
        self.persistence = PersistenceController.shared
        self.api = APIClient(baseURL: base)
        if let raw = UserDefaults.standard.string(forKey: "APPEARANCE"), let pref = AppearancePreference(rawValue: raw) {
            self.appearance = pref
        } else {
            self.appearance = .system
        }
    }

    var colorSchemeOverride: ColorScheme? {
        switch appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    func setAppearance(_ pref: AppearancePreference) {
        appearance = pref
        UserDefaults.standard.set(pref.rawValue, forKey: "APPEARANCE")
    }
}
