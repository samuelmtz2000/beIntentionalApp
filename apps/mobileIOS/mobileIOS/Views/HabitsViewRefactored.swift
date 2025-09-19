//
//  HabitsViewRefactored.swift
//  mobileIOS
//
//  Refactored modular version of HabitsView using feature-based components
//

import SwiftUI

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
        Group {
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
                        // Allow record unless game is actually in game_over
                        if app.game.state == .game_over {
                            await MainActor.run {
                                toast = ToastMessage(message: "Game is not active. Open Recovery to continue.", type: .error)
                            }
                            hasHealthAccessConfigured = await app.healthKit.hasConfiguredAccess()
                            showingRecovery = true
                            return
                        }
                        await coordinator.badVM.record(id: b.id, payWithCoins: false)
                        await coordinator.refreshAll()
                        await MainActor.run { toast = ToastMessage(message: "⚠️ \(b.name) recorded. -\(b.lifePenalty) life", type: .error) }
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.areas.isEmpty {
                    DSEmptyState(
                        icon: "square.grid.2x2",
                        title: "No Areas",
                        message: "Create areas to organize your habits",
                        actionTitle: "Add Area",
                        action: onAdd
                    )
                } else {
                    ForEach(viewModel.areas) { area in
                        DSCardRow(
                            title: area.name,
                            subtitle: "XP per level: \(area.xpPerLevel)",
                            leadingIcon: area.icon
                        )
                    }
                }
            }
            .padding()
        }
    }
}

struct StoreListView: View {
    @ObservedObject var viewModel: StoreViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.controlledBadHabits.isEmpty {
                    DSEmptyState(
                        icon: "cart",
                        title: "Store Empty",
                        message: "No controllable bad habits available for purchase"
                    )
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(viewModel.controlledBadHabits) { habit in
                            StoreItemCard(habit: habit, viewModel: viewModel)
                        }
                    }
                }
            }
            .padding()
        }
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
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.areas.isEmpty && viewModel.habits.isEmpty && viewModel.badHabits.isEmpty {
                    DSEmptyState(
                        icon: "archivebox",
                        title: "Archive Empty",
                        message: "No archived items"
                    )
                } else {
                    if !viewModel.areas.isEmpty {
                        DSSectionHeader(title: "Areas", icon: "square.stack.3d.down.forward.fill")
                        ForEach(viewModel.areas) { area in
                            DSCardRow(
                                title: area.name,
                                subtitle: "XP per level: \(area.xpPerLevel)",
                                trailingContent: AnyView(
                                    DSButton("Restore", icon: "arrow.uturn.backward", style: .secondary) {
                                        Task {
                                            await viewModel.restoreArea(id: area.id)
                                            await onRestored()
                                        }
                                    }
                                )
                            )
                        }
                    }
                    if !viewModel.habits.isEmpty {
                        DSSectionHeader(title: "Good Habits", icon: "checkmark.circle.fill")
                        ForEach(viewModel.habits) { habit in
                            DSCardRow(
                                title: habit.name,
                                subtitle: "+\(habit.xpReward) XP, +\(habit.coinReward) Coins",
                                trailingContent: AnyView(
                                    DSButton("Restore", icon: "arrow.uturn.backward", style: .secondary) {
                                        Task {
                                            await viewModel.restoreHabit(id: habit.id)
                                            await onRestored()
                                        }
                                    }
                                )
                            )
                        }
                    }
                    if !viewModel.badHabits.isEmpty {
                        DSSectionHeader(title: "Bad Habits", icon: "exclamationmark.triangle.fill")
                        ForEach(viewModel.badHabits) { bad in
                            DSCardRow(
                                title: bad.name,
                                subtitle: bad.controllable ? "Controllable (cost: \(bad.coinCost))" : "Life penalty: \(bad.lifePenalty)",
                                trailingContent: AnyView(
                                    DSButton("Restore", icon: "arrow.uturn.backward", style: .secondary) {
                                        Task {
                                            await viewModel.restoreBadHabit(id: bad.id)
                                            await onRestored()
                                        }
                                    }
                                )
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }
}
private struct ConfirmDeleteWrapper: Identifiable, Equatable {
    enum Kind { case good, bad }
    var id: String { kind == .good ? (good?.id ?? UUID().uuidString) : (bad?.id ?? UUID().uuidString) }
    let kind: Kind
    let good: GoodHabit?
    let bad: BadHabit?
}
