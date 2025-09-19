//
//  HabitsViewRefactored.swift
//  mobileIOS
//
//  Refactored modular version of HabitsView using feature-based components
//

import SwiftUI
import UIKit

private struct ConfirmDeleteWrapper: Identifiable, Equatable {
    enum Kind { case good, bad }
    var id: String { kind == .good ? (good?.id ?? UUID().uuidString) : (bad?.id ?? UUID().uuidString) }
    let kind: Kind
    let good: GoodHabit?
    let bad: BadHabit?
}

struct HabitsViewRefactored: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var coordinator = HabitsCoordinator()

    @State private var selected: NavigationSection = .habits
    @State private var showingConfig = false
    @State private var toast: ToastMessage? = nil
    @State private var showingRecovery = false
    @State private var hasHealthAccessConfigured = false
    @State private var editingGood: GoodHabit? = nil
    @State private var editingBad: BadHabit? = nil
    @State private var confirmDelete: ConfirmDeleteWrapper? = nil
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Fixed header with navigation
                NavigationHeaderContainer(
                    profileVM: coordinator.profileVM,
                    selected: $selected,
                    onConfig: { showingConfig = true }
                )
                
                // Dynamic content based on selection
                contentView
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.inline)
            .background(DSTheme.colors(for: scheme).backgroundPrimary)
            .task { await coordinator.refreshAll() }
            .onAppear {
                // Ensure header profile loads promptly even if other tasks lag
                if coordinator.profileVM.profile == nil {
                    Task { await coordinator.profileVM.refresh() }
                }
            }
            .toast($toast)
            .sheet(isPresented: $coordinator.showingAddGood) {
                AddGoodHabitSheet(
                    areas: coordinator.areasVM.areas,
                    onSave: coordinator.createGoodHabit
                )
            }
            .sheet(isPresented: $coordinator.showingAddBad) {
                AddBadHabitSheet(
                    areas: coordinator.areasVM.areas,
                    onSave: coordinator.createBadHabit
                )
            }
            .sheet(isPresented: $coordinator.showingAddArea) {
                AddAreaSheet(onSave: coordinator.createArea)
            }
            .sheet(isPresented: $showingConfig) {
                UserConfigSheet(onSaved: {
                    Task { await coordinator.profileVM.refresh() }
                })
            }
            .sheet(item: $editingGood) { h in
                EditGoodHabitSheet(habit: h, areas: coordinator.areasVM.areas) { updated in
                    Task { await coordinator.goodVM.update(habit: updated); await coordinator.refreshAll() }
                }
            }
            .sheet(item: $editingBad) { b in
                EditBadHabitSheet(habit: b, areas: coordinator.areasVM.areas) { updated in
                    Task { await coordinator.badVM.update(item: updated); await coordinator.refreshAll() }
                }
            }
            .sheet(isPresented: $showingRecovery) {
                MarathonRecoveryView(
                    game: app.game,
                    isHealthAccessConfigured: hasHealthAccessConfigured,
                    onRequestHealthAccess: {
                        Task {
                            try? await app.healthKit.requestAuthorization()
                            hasHealthAccessConfigured = await app.healthKit.hasConfiguredAccess()
                        }
                    },
                    onUpdateProgress: {
                        Task {
                            await app.game.refreshDistance(using: app.healthKit)
                            await app.game.pushRecoveryProgress()
                        }
                    }
                )
            }
            .alert(item: $confirmDelete) { wrap in
                let name = wrap.kind == .good ? (wrap.good?.name ?? "") : (wrap.bad?.name ?? "")
                return Alert(
                    title: Text("Delete \(name)?"),
                    message: Text("Are you sure you want to delete this habit?"),
                    primaryButton: .destructive(Text("Delete")) {
                        Task {
                            if wrap.kind == .good, let h = wrap.good {
                                await coordinator.goodVM.delete(id: h.id)
                            } else if let b = wrap.bad {
                                await coordinator.badVM.delete(id: b.id)
                            }
                            await coordinator.refreshAll()
                            confirmDelete = nil
                        }
                    },
                    secondaryButton: .cancel { confirmDelete = nil }
                )
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch selected {
        case .player:
            PlayerDetailView(
                profile: coordinator.profileVM.profile,
                areas: coordinator.areasVM.areas
            )
        case .habits:
            HabitsListView(
                    goodVM: coordinator.goodVM,
                    badVM: coordinator.badVM,
                    onAddGood: { coordinator.showingAddGood = true },
                    onAddBad: { coordinator.showingAddBad = true },
                    onGoodComplete: { h in
                        _ = await coordinator.goodVM.complete(id: h.id)
                        await coordinator.refreshAll()
                        await MainActor.run { toast = ToastMessage(message: "✅ \(h.name) completed! +\(h.xpReward) XP, +\(h.coinReward) coins", type: .success) }
                    },
                    onGoodEdit: { h in editingGood = h },
                    onGoodDelete: { h in await MainActor.run { confirmDelete = ConfirmDeleteWrapper(kind: .good, good: h, bad: nil) } },
                    onBadRecord: { b in
                        // Refresh game state to avoid stale gating decisions
                        await coordinator.profileVM.refresh()
                        await app.game.refreshFromServer()
                        // Allow record unless truly game over (life <= 0). If state says gameOver but life > 0, proceed.
                        if app.game.state == .gameOver {
                            let life = coordinator.profileVM.profile?.life ?? 0
                            if life <= 0 {
                                await MainActor.run {
                                    toast = ToastMessage(message: "Game is not active. Open Recovery to continue.", type: .error)
                                }
                                hasHealthAccessConfigured = await app.healthKit.hasConfiguredAccess()
                                showingRecovery = true
                                return
                            }
                        }
                        let resp = await coordinator.badVM.record(id: b.id, payWithCoins: false)
                        if let r = resp {
                            await MainActor.run {
                                if let p = coordinator.profileVM.profile {
                                    // Rebuild Profile with updated life; keep other fields
                                    let updated = Profile(
                                        life: r.user.life,
                                        coins: p.coins,
                                        level: p.level,
                                        xp: p.xp,
                                        xpPerLevel: p.xpPerLevel,
                                        config: p.config,
                                        areas: p.areas,
                                        ownedBadHabits: p.ownedBadHabits
                                    )
                                    coordinator.profileVM.profile = updated
                                }
                            }
                        }
                        await coordinator.refreshAll()
                        await MainActor.run {
                            if let avoided = resp?.avoidedPenalty, avoided {
                                toast = ToastMessage(message: "🙂 \(b.name) forgiven (used credit)", type: .success)
                            } else {
                                toast = ToastMessage(message: "⚠️ \(b.name) recorded. -\(b.lifePenalty) life", type: .error)
                            }
                        }
                    },
                    onBadEdit: { b in editingBad = b },
                    onBadDelete: { b in await MainActor.run { confirmDelete = ConfirmDeleteWrapper(kind: .bad, good: nil, bad: b) } }
                )
        case .areas:
            AreasListView(
                viewModel: coordinator.areasVM,
                onAdd: { coordinator.showingAddArea = true }
            )
        case .store:
            StoreListView(viewModel: coordinator.storeVM)
        case .archive:
            ArchiveListView(
                viewModel: coordinator.archiveVM,
                onRestored: { await coordinator.refreshAll() }
            )
        case .config:
            EmptyView()
        }
    }
}

// MARK: - Habits Coordinator

@MainActor
final class HabitsCoordinator: ObservableObject {
    let profileVM: ProfileViewModel
    let goodVM: HabitsViewModel
    let badVM: BadHabitsViewModel
    let areasVM: AreasViewModel
    let storeVM: StoreViewModel
    let archiveVM: ArchiveViewModel
    
    @Published var showingAddGood = false
    @Published var showingAddBad = false
    @Published var showingAddArea = false
    
    init() {
        let baseURL = URL(string: UserDefaults.standard.string(forKey: "API_BASE_URL") ?? "http://localhost:4000")!
        let api = APIClient(baseURL: baseURL)
        self.profileVM = ProfileViewModel(api: api)
        self.goodVM = HabitsViewModel(api: api)
        self.badVM = BadHabitsViewModel(api: api)
        self.areasVM = AreasViewModel(api: api)
        self.storeVM = StoreViewModel(api: api)
        self.archiveVM = ArchiveViewModel(api: api)
    }
    
    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.profileVM.refresh() }
            group.addTask { await self.areasVM.refresh() }
            group.addTask { await self.goodVM.refresh() }
            group.addTask { await self.badVM.refresh() }
            group.addTask { await self.storeVM.refresh() }
            group.addTask { await self.archiveVM.refresh() }
        }
    }
    
    func createGoodHabit(areaId: String, name: String, xp: Int, coins: Int, cadence: String?, active: Bool) async {
        await goodVM.create(
            areaId: areaId,
            name: name,
            xpReward: xp,
            coinReward: coins,
            cadence: cadence,
            isActive: active
        )
        showingAddGood = false
        await refreshAll()
    }
    
    func createBadHabit(areaId: String?, name: String, penalty: Int, controllable: Bool, cost: Int, active: Bool) async {
        await badVM.create(
            areaId: areaId?.isEmpty == true ? nil : areaId,
            name: name,
            lifePenalty: penalty,
            controllable: controllable,
            coinCost: cost,
            isActive: active
        )
        showingAddBad = false
        await refreshAll()
    }
    
    func createArea(name: String, icon: String?, xp: Int, curve: String, multiplier: Double) async {
        await areasVM.create(
            name: name,
            icon: icon,
            xpPerLevel: xp,
            levelCurve: curve,
            levelMultiplier: multiplier
        )
        showingAddArea = false
        await refreshAll()
    }
}

// MARK: - Feature List Views

private struct StatsCard: View {
    let profile: Profile
    let areas: [Area]
    
    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Overall Stats")
                    .dsFont(.headerMD)
                
                HStack {
                    Label("Life", systemImage: "heart.fill")
                    Spacer()
                    Text("\(profile.life)/100")
                }
                
                HStack {
                    Label("Coins", systemImage: "creditcard")
                    Spacer()
                    Text("\(profile.coins)")
                }
                
                Divider()
                
                Text("Area Progress")
                    .dsFont(.headerMD)
                
                ForEach(profile.areas, id: \.areaId) { areaLevel in
                    AreaProgressRow(
                        areaLevel: areaLevel,
                        areaMeta: areas.first { $0.id == areaLevel.areaId }
                    )
                }
            }
        }
    }
}

// MARK: - Feature List Views

struct PlayerDetailView: View {
    let profile: Profile?
    let areas: [Area]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let p = profile {
                    StatsCard(profile: p, areas: areas)
                } else {
                    DSEmptyState(
                        icon: "person.crop.circle",
                        title: "Loading Profile",
                        message: "Please wait while we load your stats..."
                    )
                }
            }
            .padding()
        }
    }
}

struct AreaProgressRow: View {
    let areaLevel: ProfileArea
    let areaMeta: Area?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(areaLevel.name)
                    .bold()
                Spacer()
                Text("Lvl \(areaLevel.level)")
            }
            
            let need = PlayerHelper.areaXpNeeded(
                level: areaLevel.level,
                base: areaLevel.xpPerLevel,
                curve: areaMeta?.levelCurve ?? "linear",
                multiplier: areaMeta?.levelMultiplier ?? 1.5
            )
            
            DSProgressBar(
                value: Double(areaLevel.xp),
                total: Double(max(need, 1)),
                label: "XP to next level",
                showPercentage: true
            )
        }
    }
}

struct AreasListView: View {
    @ObservedObject var viewModel: AreasViewModel
    var onAdd: () -> Void
    
    @State private var editingArea: Area? = nil
    @State private var confirmDelete: Area? = nil
    
    var body: some View {
        List {
            Section {
                if viewModel.areas.isEmpty {
                    DSEmptyState(
                        icon: "square.grid.2x2",
                        title: "No Areas",
                        message: "Create areas to organize your habits",
                        actionTitle: "Add Area",
                        action: onAdd
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.areas) { area in
                        DSCard {
                            HStack(alignment: .center, spacing: 12) {
                                if let symRaw = area.icon?.trimmingCharacters(in: .whitespacesAndNewlines), !symRaw.isEmpty {
                                    if UIImage(systemName: symRaw) != nil {
                                        Image(systemName: symRaw)
                                    } else {
                                        Text(symRaw).dsFont(.body)
                                    }
                                } else {
                                    Text("📦").dsFont(.body)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(area.name).dsFont(.body)
                                    Text("XP per level: \(area.xpPerLevel)").dsFont(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button { editingArea = area } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                            Button(role: .destructive) { confirmDelete = area } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }
            } header: {
                DSSectionHeader(
                    title: "Areas",
                    icon: "square.grid.2x2",
                    trailingIcon: "plus.circle.fill",
                    onTrailingTap: onAdd
                )
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .sheet(item: $editingArea) { area in
                AreaEditSheet(area: area, onSave: { updated in Task { await viewModel.update(area: updated) } }, onDelete: { Task { await viewModel.delete(id: area.id) } })
            }
            .alert(item: $confirmDelete) { area in
                Alert(title: Text("Delete \(area.name)?"), message: Text("Are you sure you want to delete this area?"), primaryButton: .destructive(Text("Delete")) {
                    Task { await viewModel.delete(id: area.id) }
                }, secondaryButton: .cancel())
            }
        }
    }
    }
    
    struct StoreListView: View {
        @ObservedObject var viewModel: StoreViewModel
        
        var body: some View {
            List {
                Section {
                    if viewModel.controlledBadHabits.isEmpty {
                        DSEmptyState(
                            icon: "cart",
                            title: "Store Empty",
                            message: "No controllable bad habits available for purchase"
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(viewModel.controlledBadHabits) { habit in
                            DSCard {
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(habit.name).dsFont(.body)
                                        Label("Cost: \(habit.coinCost)", systemImage: "creditcard").dsFont(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button { Task { await viewModel.buy(cosmeticId: habit.id) } } label: { Label("Buy", systemImage: "cart") }.tint(.green)
                            }
                        }
                    }
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: "cart")
                        Text("Store").dsFont(.headerMD).bold()
                        Spacer()
                        HStack(spacing: 6) { Label("Coins", systemImage: "creditcard"); Text("\(viewModel.coins)") }.dsFont(.caption).foregroundStyle(.secondary)
                    }
                }
                if !viewModel.ownedBadHabits.isEmpty {
                    Section {
                        ForEach(viewModel.ownedBadHabits, id: \.id) { obh in
                            HStack { Text(obh.name).dsFont(.body); Spacer(); Text("x\(obh.count)").dsFont(.caption).foregroundStyle(.secondary) }
                                .listRowBackground(Color.clear)
                        }
                    } header: { HStack{ Image(systemName: "checkmark.seal"); Text("Owned (Credits)").dsFont(.headerMD).bold() } }
                }
            }
            .listStyle(.plain)
        }
    }
    
    struct StoreItemCard: View {
        let habit: BadHabit
        @ObservedObject var viewModel: StoreViewModel
        
        var body: some View {
            DSCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(habit.name)
                        .dsFont(.body)
                        .lineLimit(2)
                    
                    Label("\(habit.coinCost) coins", systemImage: "creditcard")
                        .dsFont(.caption)
                        .foregroundStyle(.secondary)
                    
                    DSButton("Buy", style: .primary) {
                        Task {
                            await viewModel.buy(cosmeticId: habit.id)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    struct ArchiveListView: View {
        @ObservedObject var viewModel: ArchiveViewModel
        var onRestored: () async -> Void
        
        var body: some View {
            List {
                if viewModel.areas.isEmpty && viewModel.habits.isEmpty && viewModel.badHabits.isEmpty {
                    Section { DSEmptyState(icon: "archivebox", title: "Archive Empty", message: "No archived items").listRowBackground(Color.clear) }
                }
                if !viewModel.areas.isEmpty {
                    Section {
                        ForEach(viewModel.areas) { area in
                            DSCardRow(title: area.name, subtitle: "XP per level: \(area.xpPerLevel)")
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing) {
                                    Button { Task { await viewModel.restoreArea(id: area.id); await onRestored() } } label: { Label("Restore", systemImage: "arrow.uturn.backward") }.tint(.green)
                                }
                        }
                    } header: { HStack{ Image(systemName:"square.stack.3d.down.forward.fill"); Text("Areas").dsFont(.headerMD).bold() } }
                }
                if !viewModel.habits.isEmpty {
                    Section {
                        ForEach(viewModel.habits) { h in
                            DSCardRow(title: h.name, subtitle: "+\(h.xpReward) XP, +\(h.coinReward) Coins")
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing) {
                                    Button { Task { await viewModel.restoreHabit(id: h.id); await onRestored() } } label: { Label("Restore", systemImage: "arrow.uturn.backward") }.tint(.green)
                                }
                        }
                    } header: { HStack{ Image(systemName:"checkmark.circle.fill"); Text("Good Habits").dsFont(.headerMD).bold() } }
                }
                if !viewModel.badHabits.isEmpty {
                    Section {
                        ForEach(viewModel.badHabits) { b in
                            DSCardRow(title: b.name, subtitle: b.controllable ? "Controllable (cost: \(b.coinCost))" : "Life penalty: \(b.lifePenalty)")
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing) {
                                    Button { Task { await viewModel.restoreBadHabit(id: b.id); await onRestored() } } label: { Label("Restore", systemImage: "arrow.uturn.backward") }.tint(.green)
                                }
                        }
                    } header: { HStack{ Image(systemName:"exclamationmark.triangle.fill"); Text("Bad Habits").dsFont(.headerMD).bold() } }
                }
            }
            .listStyle(.plain)
        }
    }
