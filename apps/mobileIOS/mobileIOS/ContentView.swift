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
            AreasView()
                .tabItem { Label("Areas", systemImage: "square.grid.2x2") }
            HabitsView()
                .tabItem { Label("Habits", systemImage: "checklist") }
            StoreView()
                .tabItem { Label("Store", systemImage: "bag") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.doc.horizontal") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#Preview {
    MainTabView()
}
