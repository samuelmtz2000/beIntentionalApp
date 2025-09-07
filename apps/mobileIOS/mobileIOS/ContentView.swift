//
//  ContentView.swift
//  mobileIOS
//
//  Created by Samuel Martinez on 07/09/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
            HabitsView()
                .tabItem { Label("Habits", systemImage: "checklist") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#Preview {
    MainTabView()
}
