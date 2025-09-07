import SwiftUI

struct HabitsView: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var vm: HabitsViewModel
    @StateObject private var badVM: BadHabitsViewModel
    @State private var showingAddGood = false
    @State private var showingAddBad = false

    init() {
        let app = AppModel()
        _vm = StateObject(wrappedValue: HabitsViewModel(api: app.api))
        _badVM = StateObject(wrappedValue: BadHabitsViewModel(api: app.api))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Good Habits") {
                    ForEach(vm.habits) { habit in
                        NavigationLink(destination: HabitDetailView(habit: habit) { updated in
                            Task { await vm.update(habit: updated) }
                        } onDelete: {
                            Task { await vm.delete(id: habit.id) }
                        }) {
                            VStack(alignment: .leading) {
                                Text(habit.name).font(.headline)
                                Text("XP +\(habit.xpReward) • Coins +\(habit.coinReward)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .contextMenu { Button(role: .destructive) { Task { await vm.delete(id: habit.id) } } label: { Label("Delete", systemImage: "trash") } }
                        .swipeActions { Button(role: .destructive) { Task { await vm.delete(id: habit.id) } } label: { Label("Delete", systemImage: "trash") } }
                    }
                }
                Section("Bad Habits") {
                    ForEach(badVM.items) { item in
                        NavigationLink(destination: BadHabitDetailView(item: item) { updated in
                            Task { await badVM.update(item: updated) }
                        } onDelete: {
                            Task { await badVM.delete(id: item.id) }
                        }) {
                            VStack(alignment: .leading) {
                                Text(item.name).font(.headline)
                                Text(item.controllable ? "Controllable • Cost \(item.coinCost)" : "Penalty \(item.lifePenalty)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions { Button(role: .destructive) { Task { await badVM.delete(id: item.id) } } label: { Label("Delete", systemImage: "trash") } }
                    }
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { showingAddGood = true } label: { Label("New Good Habit", systemImage: "plus") }
                        Button { showingAddBad = true } label: { Label("New Bad Habit", systemImage: "bolt.slash") }
                    } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .navigationBarTrailing) { Button { Task { await vm.refresh(); await badVM.refresh() } } label: { Image(systemName: "arrow.clockwise") } }
            }
            .sheet(isPresented: $showingAddGood) { NewHabitSheet { areaId, name, xp, coins, cadence, active in
                Task { await vm.create(areaId: areaId, name: name, xpReward: xp, coinReward: coins, cadence: cadence, isActive: active) }
            } }
            .sheet(isPresented: $showingAddBad) { NewBadHabitSheet { areaId, name, penalty, controllable, cost, active in
                Task { await badVM.create(areaId: areaId.isEmpty ? nil : areaId, name: name, lifePenalty: penalty, controllable: controllable, coinCost: cost, isActive: active) }
            } }
            .task { await vm.refresh(); await badVM.refresh() }
            .alert(item: $vm.apiError) { err in Alert(title: Text("Error"), message: Text(err.message), dismissButton: .default(Text("OK"))) }
            .alert(item: $badVM.apiError) { err in Alert(title: Text("Error"), message: Text(err.message), dismissButton: .default(Text("OK"))) }
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

struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var habit: GoodHabit
    @State private var areaIdInput: String
    var onSave: (GoodHabit) -> Void
    var onDelete: () -> Void

    init(habit: GoodHabit, onSave: @escaping (GoodHabit) -> Void, onDelete: @escaping () -> Void) {
        _habit = State(initialValue: habit)
        _areaIdInput = State(initialValue: habit.areaId)
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Name", text: $habit.name)
                TextField("Area ID", text: $areaIdInput)
                TextField("Cadence", text: Binding(get: { habit.cadence ?? "" }, set: { habit.cadence = $0.isEmpty ? nil : $0 }))
                Toggle("Active", isOn: $habit.isActive)
            }
            Section("Rewards") {
                Stepper("XP: \(habit.xpReward)", value: $habit.xpReward, in: 1...1000)
                Stepper("Coins: \(habit.coinReward)", value: $habit.coinReward, in: 0...1000)
            }
            Section {
                Button("Save") {
                    let updated = GoodHabit(id: habit.id, areaId: areaIdInput, name: habit.name, xpReward: habit.xpReward, coinReward: habit.coinReward, cadence: habit.cadence, isActive: habit.isActive)
                    onSave(updated); dismiss()
                }.buttonStyle(.borderedProminent)
                Button("Delete", role: .destructive) { onDelete(); dismiss() }
            }
        }
        .navigationTitle("Edit Habit")
    }
}

struct NewBadHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var areaId: String = ""
    @State private var name: String = ""
    @State private var lifePenalty: Int = 5
    @State private var controllable: Bool = false
    @State private var coinCost: Int = 0
    @State private var active: Bool = true

    var onCreate: (String, String, Int, Bool, Int, Bool) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Area ID (optional)", text: $areaId)
                    Toggle("Controllable", isOn: $controllable)
                    Toggle("Active", isOn: $active)
                }
                Section("Penalty / Cost") {
                    Stepper("Life Penalty: \(lifePenalty)", value: $lifePenalty, in: 1...100)
                    Stepper("Coin Cost: \(coinCost)", value: $coinCost, in: 0...100)
                }
            }
            .navigationTitle("New Bad Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Create") { onCreate(areaId, name, lifePenalty, controllable, coinCost, active); dismiss() }.disabled(name.isEmpty) }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct BadHabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var item: BadHabit
    @State private var areaIdInput: String
    var onSave: (BadHabit) -> Void
    var onDelete: () -> Void

    init(item: BadHabit, onSave: @escaping (BadHabit) -> Void, onDelete: @escaping () -> Void) {
        _item = State(initialValue: item)
        _areaIdInput = State(initialValue: item.areaId ?? "")
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Name", text: $item.name)
                TextField("Area ID (optional)", text: $areaIdInput)
                Toggle("Controllable", isOn: $item.controllable)
                Toggle("Active", isOn: $item.isActive)
            }
            Section("Costs") {
                Stepper("Life Penalty: \(item.lifePenalty)", value: $item.lifePenalty, in: 1...100)
                Stepper("Coin Cost: \(item.coinCost)", value: $item.coinCost, in: 0...100)
            }
            Section {
                Button("Save") {
                    let updated = BadHabit(id: item.id, areaId: areaIdInput.isEmpty ? nil : areaIdInput, name: item.name, lifePenalty: item.lifePenalty, controllable: item.controllable, coinCost: item.coinCost, isActive: item.isActive)
                    onSave(updated); dismiss()
                }.buttonStyle(.borderedProminent)
                Button("Delete", role: .destructive) { onDelete(); dismiss() }
            }
        }
        .navigationTitle("Edit Bad Habit")
    }
}
