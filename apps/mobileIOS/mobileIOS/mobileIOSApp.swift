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
        }
    }
}

final class AppModel: ObservableObject {
    @Published var apiBaseURL: URL = URL(string: UserDefaults.standard.string(forKey: "API_BASE_URL") ?? "http://localhost:4000")!
    let api: APIClient
    let persistence: PersistenceController

    init() {
        self.persistence = PersistenceController.shared
        self.api = APIClient(baseURL: apiBaseURL)
    }
}
