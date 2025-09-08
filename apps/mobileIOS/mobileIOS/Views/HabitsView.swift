import SwiftUI

struct HabitsView: View {
    enum SectionKind: String, CaseIterable { case player = "Player", habits = "Habits", areas = "Areas", store = "Store" }

    @EnvironmentObject private var app: AppModel
    @StateObject private var profileVM: ProfileViewModel
    @StateObject private var goodVM: HabitsViewModel
    @StateObject private var badVM: BadHabitsViewModel
    @StateObject private var areasVM: AreasViewModel
    @StateObject private var storeVM: StoreViewModel

    @State private var showingAddGood = false
    @State private var showingAddBad = false
    @State private var showingAddArea = false
    @State private var showingConfig = false
    @State private var selected: SectionKind = .habits

    init() {
        let app = AppModel()
        _profileVM = StateObject(wrappedValue: ProfileViewModel(api: app.api))
        _goodVM = StateObject(wrappedValue: HabitsViewModel(api: app.api))
        _badVM = StateObject(wrappedValue: BadHabitsViewModel(api: app.api))
        _areasVM = StateObject(wrappedValue: AreasViewModel(api: app.api))
        _storeVM = StateObject(wrappedValue: StoreViewModel(api: app.api))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PlayerHeader(profile: profileVM.profile, onLogToday: { selected = .habits }, onOpenStore: { selected = .store })
                    TileNav(selected: $selected)
                    content
                }.padding()
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingConfig = true } label: { Image(systemName: "gearshape") }
                }
            }
            .task { await refreshAll() }
            .refreshable { await refreshAll() }
            .sheet(isPresented: $showingAddGood) { NewHabitSheet { areaId, name, xp, coins, cadence, active in Task { await goodVM.create(areaId: areaId, name: name, xpReward: xp, coinReward: coins, cadence: cadence, isActive: active); await refreshAll() } } }
            .sheet(isPresented: $showingAddBad) { NewBadHabitSheet { areaId, name, penalty, controllable, cost, active in Task { await badVM.create(areaId: areaId.isEmpty ? nil : areaId, name: name, lifePenalty: penalty, controllable: controllable, coinCost: cost, isActive: active); await refreshAll() } } }
            .sheet(isPresented: $showingAddArea) { NewAreaSheet { name, icon, xp, curve in Task { await areasVM.create(name: name, icon: icon, xpPerLevel: xp, levelCurve: curve); await refreshAll() } } }
            .sheet(isPresented: $showingConfig) { UserConfigSheet(onSaved: { Task { await profileVM.refresh() } }) }
        }
    }

    private var content: some View {
        Group {
            switch selected {
            case .player: PlayerPanel(profile: profileVM.profile)
            case .habits: CombinedHabitsPanel(goodVM: goodVM, badVM: badVM, onAddGood: { showingAddGood = true }, onAddBad: { showingAddBad = true })
            case .areas: AreasPanel(vm: areasVM, onAdd: { showingAddArea = true })
            case .store: StorePanel(vm: storeVM)
            }
        }
    }

    private func refreshAll() async {
        await profileVM.refresh()
        await goodVM.refresh()
        await badVM.refresh()
        await areasVM.refresh()
        await storeVM.refresh()
    }
}

private struct PlayerHeader: View {
    let profile: Profile?
    var onLogToday: () -> Void
    var onOpenStore: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                if let p = profile {
                    VStack(alignment: .leading) {
                        HStack { Text("Lvl \(p.level)").bold().padding(6).background(Capsule().fill(Color.blue.opacity(0.15))) }
                        let need = xpNeeded(level: p.level, base: p.xpPerLevel, curve: p.config?.levelCurve ?? "linear", multiplier: p.config?.levelMultiplier ?? 1.5)
                        ProgressView(value: Double(p.xp), total: Double(max(need,1))) {
                            HStack(spacing: 6) {
                                Text("XP to next")
                                Image(systemName: "arrow.right")
                                Text("\(p.xp) from \(need)")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Label("\(p.coins)", systemImage: "creditcard").labelStyle(.titleAndIcon)
                        Label("Streak N/A", systemImage: "flame")
                            .foregroundStyle(.orange)
                    }
                } else {
                    Text("Loading...")
                }
            }
            // Removed quick action buttons to simplify header; navigation chips below handle section switching
        }
        .accessibilityElement(children: .contain)
    }
}

private func xpNeeded(level: Int, base: Int, curve: String, multiplier: Double) -> Int {
    if curve == "exp" {
        let m = max(1.0, multiplier)
        let powv = pow(m, Double(max(0, level - 1)))
        return max(1, Int(floor(Double(base) * powv)))
    } else {
        return max(1, base)
    }
}

private struct TileNav: View {
    @Binding var selected: HabitsView.SectionKind
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(HabitsView.SectionKind.allCases, id: \.self) { kind in
                    let isSelected = (selected == kind)
                    Button(action: { selected = kind }) {
                        Text(kind.rawValue)
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(isSelected ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.15))
                            )
                    }
                    .accessibilityLabel(Text(kind.rawValue))
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
    }
}

private struct PlayerPanel: View {
    let profile: Profile?
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let p = profile {
                Text("Overall").font(.headline)
                HStack { Label("Life", systemImage: "heart.fill"); Spacer(); Text("\(p.life)") }
                HStack { Label("Coins", systemImage: "creditcard"); Spacer(); Text("\(p.coins)") }
                Divider()
                Text("Per Area").font(.headline)
                ForEach(p.areas, id: \.areaId) { a in
                    VStack(alignment: .leading) {
                        HStack { Text(a.name).bold(); Spacer(); Text("Lvl \(a.level)") }
                        ProgressView(value: Double(a.xp), total: Double(max(a.xpPerLevel,1)))
                    }
                }
            } else {
                Text("Loading stats...")
            }
        }
    }
}

private struct CombinedHabitsPanel: View {
    @ObservedObject var goodVM: HabitsViewModel
    @ObservedObject var badVM: BadHabitsViewModel
    var onAddGood: () -> Void
    var onAddBad: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Habits").font(.headline)
                Spacer()
                Menu {
                    Button("New Good Habit", action: onAddGood)
                    Button("New Bad Habit", action: onAddBad)
                } label: {
                    Image(systemName: "plus")
                }
            }
            Group {
                Text("Good").bold()
                ForEach(goodVM.habits) { habit in
                    VStack(alignment: .leading) {
                        HStack { Text(habit.name).font(.headline); Spacer(); Text("XP +\(habit.xpReward) • Coins +\(habit.coinReward)").font(.caption).foregroundStyle(.secondary) }
                        HStack {
                            Button("Edit") { /* open via sheet */ }.disabled(true)
                            Button("Delete", role: .destructive) { Task { await goodVM.delete(id: habit.id) } }
                        }.buttonStyle(.bordered)
                    }
                }
                Divider().padding(.vertical, 4)
                Text("Bad").bold()
                ForEach(badVM.items) { item in
                    VStack(alignment: .leading) {
                        HStack { Text(item.name).font(.headline); Spacer(); Text("Penalty \(item.lifePenalty)").font(.caption).foregroundStyle(.secondary) }
                        HStack {
                            Button("Edit") { /* open via sheet */ }.disabled(true)
                            Button("Delete", role: .destructive) { Task { await badVM.delete(id: item.id) } }
                        }.buttonStyle(.bordered)
                    }
                }
            }
        }
    }
}

private struct AreasPanel: View {
    @ObservedObject var vm: AreasViewModel
    var onAdd: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text("Areas").font(.headline); Spacer(); Button("New Area", action: onAdd) }
            ForEach(vm.areas) { area in
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Text(area.icon ?? "🗂️"); Text(area.name); Spacer(); Text("XP/Level: \(area.xpPerLevel)").font(.caption).foregroundStyle(.secondary) }
                    HStack { Button("Edit"){}.disabled(true); Button("Delete", role: .destructive) { Task { await vm.delete(id: area.id) } } }
                        .buttonStyle(.bordered)
                }
            }
        }
    }
}

private struct StorePanel: View {
    @ObservedObject var vm: StoreViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Store").font(.headline)
            HStack { Label("Coins", systemImage: "creditcard"); Spacer(); Text("\(vm.coins)") }
            Divider()
            Text("Bad Habits Store").bold()
            ForEach(vm.controlledBadHabits) { b in
                HStack {
                    VStack(alignment: .leading) {
                        Text(b.name).font(.headline)
                        Text("Penalty \(b.lifePenalty) • Cost \(b.coinCost)🪙").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    let owned = vm.ownedBadHabits.first(where: { $0.id == b.id })?.count ?? 0
                    if owned > 0 { Text("Owned: \(owned)").font(.caption) }
                    Button("Buy") { Task { await vm.buy(cosmeticId: b.id) } }.buttonStyle(.borderedProminent)
                }
            }
            Divider()
            Text("Owned (Credits)").bold()
            ForEach(vm.ownedBadHabits, id: \.id) { obh in HStack { Text(obh.name); Spacer(); Text("x\(obh.count)").font(.caption) } }
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
