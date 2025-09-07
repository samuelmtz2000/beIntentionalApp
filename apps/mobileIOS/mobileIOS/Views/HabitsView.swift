import SwiftUI

struct HabitsView: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var vm: HabitsViewModel
    @State private var showingAdd = false

    init() {
        let app = AppModel()
        _vm = StateObject(wrappedValue: HabitsViewModel(api: app.api))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.habits) { habit in
                    NavigationLink(value: habit.id) {
                        VStack(alignment: .leading) {
                            Text(habit.name).font(.headline)
                            Text("XP +\(habit.xpReward) • Coins +\(habit.coinReward)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) { Task { await vm.delete(id: habit.id) } } label: { Label("Delete", systemImage: "trash") }
                    }
                    .swipeActions {
                        Button(role: .destructive) { Task { await vm.delete(id: habit.id) } } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .navigationBarTrailing) { Button { Task { await vm.refresh() } } label: { Image(systemName: "arrow.clockwise") } }
            }
            .sheet(isPresented: $showingAdd) { NewHabitSheet { areaId, name, xp, coins, cadence, active in
                Task { await vm.create(areaId: areaId, name: name, xpReward: xp, coinReward: coins, cadence: cadence, isActive: active) }
            } }
            .task { await vm.refresh() }
            .alert(item: $vm.error) { err in Alert(title: Text("Error"), message: Text(err.message), dismissButton: .default(Text("OK"))) }
        }
    }
}

struct NewHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var areaId: String = "area-health"
    @State private var name: String = ""
    @State private var xp: Int = 10
    @State private var coins: Int = 5
    @State private var cadence: String = "daily"
    @State private var active: Bool = true

    var onCreate: (String, String, Int, Int, String?, Bool) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Area ID", text: $areaId)
                    TextField("Cadence", text: $cadence)
                    Toggle("Active", isOn: $active)
                }
                Section("Rewards") {
                    Stepper("XP Reward: \(xp)", value: $xp, in: 1...100)
                    Stepper("Coin Reward: \(coins)", value: $coins, in: 0...100)
                }
            }
            .navigationTitle("New Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Create") { onCreate(areaId, name, xp, coins, cadence.isEmpty ? nil : cadence, active); dismiss() }.disabled(name.isEmpty) }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

