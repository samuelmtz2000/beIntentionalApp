//
//  ContentView.swift
//  mobileIOS
//
//  Created by Samuel Martinez on 07/09/25.
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        let c = DSTheme.colors(for: scheme)
        return TabView {
            HabitsViewRefactored()
                .tabItem { Label("Habits", systemImage: "checklist") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(c.accentSecondary)
        .toolbarBackground(c.backgroundSecondary, for: .tabBar)
    }
}

#Preview {
    MainTabView()
}
