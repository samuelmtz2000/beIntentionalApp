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
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Fixed header with navigation
                NavigationHeaderContainer(
                    profile: coordinator.profileVM.profile,
                    selected: $selected,
                    onConfig: { showingConfig = true }
                )
                
                // Dynamic content based on selection
                contentView
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.inline)
            .background(DSTheme.colors(for: scheme).backgroundPrimary)
            .task {
                await coordinator.refreshAll()
            }
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
                    onAddBad: { coordinator.showingAddBad = true }
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
