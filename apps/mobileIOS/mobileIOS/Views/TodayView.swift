import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var profileVM: ProfileViewModel
    @StateObject private var habitsVM: HabitsViewModel

    init() {
        let app = AppModel()
        _profileVM = StateObject(wrappedValue: ProfileViewModel(api: app.api))
        _habitsVM = StateObject(wrappedValue: HabitsViewModel(api: app.api))
    }

    var body: some View {
        NavigationStack {
            List {
                if let p = profileVM.profile {
                    Section("Overview") {
                        HStack { Label("Life", systemImage: "heart.fill"); Spacer(); Text("\(p.life)") }
                        HStack { Label("Coins", systemImage: "circle.grid.2x2.fill"); Spacer(); Text("\(p.coins)") }
                    }
                    Section("Areas") {
                        ForEach(p.areas, id: \.areaId) { a in
                            HStack {
                                Text(a.name)
                                Spacer()
                                Text("Lvl \(a.level) • \(a.xp)/\(a.xpPerLevel)").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Quick Habits") {
                    ForEach(habitsVM.habits) { h in
                        HStack {
                            Text(h.name)
                            Spacer()
                            Button("Done") { Task { _ = await habitsVM.complete(id: h.id); await profileVM.refresh() } }
                                .buttonStyle(.borderedProminent)
                        }
                        .contextMenu { Button(role: .destructive) { Task { await habitsVM.delete(id: h.id) } } label: { Label("Delete", systemImage: "trash") } }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button { Task { _ = await habitsVM.complete(id: h.id); await profileVM.refresh() } } label: { Label("Complete", systemImage: "checkmark.circle.fill") }.tint(.green)
                        }
                    }
                }
            }
            .navigationTitle("Today")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { Task { await load() } } label: { Image(systemName: "arrow.clockwise") } } }
            .refreshable { await load() }
            .task { await load() }
            .alert(item: $habitsVM.apiError) { err in Alert(title: Text("Error"), message: Text(err.message), dismissButton: .default(Text("OK"))) }
            .alert(item: $profileVM.apiError) { err in Alert(title: Text("Error"), message: Text(err.message), dismissButton: .default(Text("OK"))) }
        }
    }

    private func load() async { await profileVM.refresh(); await habitsVM.refresh() }
}

#Preview { TodayView().environmentObject(AppModel()) }
