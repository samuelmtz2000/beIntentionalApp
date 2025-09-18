import SwiftUI
import UIKit

struct HabitsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    enum SectionKind: String, CaseIterable { case player = "Player", habits = "Habits", areas = "Areas", store = "Store", archive = "Archive", config = "Config" }

    @EnvironmentObject private var app: AppModel
    @StateObject private var profileVM: ProfileViewModel
    @StateObject private var goodVM: HabitsViewModel
    @StateObject private var badVM: BadHabitsViewModel
    @StateObject private var areasVM: AreasViewModel
    @StateObject private var storeVM: StoreViewModel
    @StateObject private var archiveVM: ArchiveViewModel

    @State private var showingAddGood = false
    @State private var showingAddBad = false
    @State private var showingAddArea = false
    @State private var showingConfig = false
    @State private var selected: SectionKind = .habits
    @State private var toast: ToastMessage? = nil
    @State private var showGameOverModal = false
    @State private var showingRecovery = false
    @State private var hasHealthAccessConfigured = false
    @State private var showRecoveryCompletion = false
    @State private var pendingLocalCompletion = false

    init() {
        let app = AppModel()
        _profileVM = StateObject(wrappedValue: ProfileViewModel(api: app.api))
        _goodVM = StateObject(wrappedValue: HabitsViewModel(api: app.api))
        _badVM = StateObject(wrappedValue: BadHabitsViewModel(api: app.api))
        _areasVM = StateObject(wrappedValue: AreasViewModel(api: app.api))
        _storeVM = StateObject(wrappedValue: StoreViewModel(api: app.api))
        _archiveVM = StateObject(wrappedValue: ArchiveViewModel(api: app.api))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Fixed header section
                VStack(spacing: 0) {
                LegacyPlayerHeader(profile: profileVM.profile, onLogToday: { selected = .habits }, onOpenStore: { selected = .store })
                    TileNav(selected: $selected, onConfig: { showingConfig = true })
                    if app.game.state == .recovery {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "figure.run")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Recovery in progress")
                                    .dsFont(.body)
                                Text("Bad habits are disabled until recovery is complete.")
                                    .dsFont(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Details") {
                                Task {
                                    let configured = await app.healthKit.hasConfiguredAccess()
                                    if app.game.state == .recovery || configured {
                                        hasHealthAccessConfigured = configured
                                        showingRecovery = true
                                    } else {
                                        showGameOverModal = true
                                    }
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                }
                .background(DSTheme.colors(for: scheme).backgroundSecondary)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            handleHeaderSwipe(translation: value.translation.width)
                        }
                )
                
                // Scrollable body content
                Group {
                    if selected == .habits {
                        CombinedHabitsBodyPanel(
                            goodVM: goodVM,
                            badVM: badVM,
                            onRefresh: { await refreshAll() },
                            onAddGood: { showingAddGood = true },
                            onAddBad: { showingAddBad = true },
                            onBadHabitRecorded: { await onBadHabitRecorded() },
                            onOpenRecovery: { configured in
                                hasHealthAccessConfigured = configured
                                showingRecovery = true
                            },
                            onShowSuccessToast: showSuccessToast,
                            onShowErrorToast: showErrorToast
                        )
                    } else if selected == .areas {
                        AreasPanelBody(vm: areasVM, onAdd: { showingAddArea = true })
                    } else if selected == .store {
                        StorePanelBody(vm: storeVM)
                    } else if selected == .archive {
                        ArchivePanelBody(vm: archiveVM, onRestored: { await refreshAll() })
                    } else if selected == .player {
                        PlayerPanelBody(profile: profileVM.profile, areasMeta: areasVM.areas)
                    } else {
                        EmptyView()
                    }
                }
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.inline)
            .background(DSTheme.colors(for: scheme).backgroundPrimary)
            .task {
                await app.game.refreshFromServer()
                await refreshAll()
                await checkAndPresentGameOver()
            }
            .sheet(isPresented: $showingAddGood) {
                NewHabitSheet(areas: areasVM.areas) { areaId, name, xp, coins, cadence, active in
                    Task {
                        await goodVM.create(areaId: areaId, name: name, xpReward: xp, coinReward: coins, cadence: cadence, isActive: active)
                        await refreshAll()
                    }
                }
            }
            .sheet(isPresented: $showingAddBad) {
                NewBadHabitSheet(areas: areasVM.areas) { areaId, name, penalty, controllable, cost, active in
                    Task {
                        await badVM.create(areaId: areaId.isEmpty ? nil : areaId, name: name, lifePenalty: penalty, controllable: controllable, coinCost: cost, isActive: active)
                        await refreshAll()
                    }
                }
            }
            .sheet(isPresented: $showingAddArea) { NewAreaSheet { name, icon, xp, curve, mult in Task { await areasVM.create(name: name, icon: icon, xpPerLevel: xp, levelCurve: curve, levelMultiplier: mult); await refreshAll() } } }
            .sheet(isPresented: $showingConfig) { UserConfigSheet(onSaved: { Task { await profileVM.refresh() } }) }
            .toast($toast)
            .sheet(isPresented: $showGameOverModal) {
                GameOverModal(onStartRecovery: {
                    withAnimation { showGameOverModal = false }
                    // Mark recovery start locally; backend state is already set by trigger.
                    app.game.startRecoveryNow()
                    showingRecovery = true
                })
            }
            .sheet(isPresented: $showingRecovery) {
                MarathonRecoveryView(
                    game: app.game,
                    isHealthAccessConfigured: hasHealthAccessConfigured,
                    onRequestHealthAccess: {
                        Task {
                            try? await app.healthKit.requestAuthorization()
                            hasHealthAccessConfigured = await app.healthKit.hasConfiguredAccess()
                            if !hasHealthAccessConfigured {
                                await MainActor.run { showErrorToast(message: "Health access not granted. Please enable to track recovery.") }
                            }
                        }
                    },
                    onUpdateProgress: {
                        Task {
                            await app.game.refreshDistance(using: app.healthKit)
                            // If locally eligible, show celebration first; complete after user closes modal
                            if app.game.recoveryDistance >= app.game.recoveryTarget {
                                await MainActor.run {
                                    pendingLocalCompletion = true
                                    showRecoveryCompletion = true
                                }
                            } else {
                                await app.game.pushRecoveryProgress()
                            }
                        }
                    }
                )
                .task { hasHealthAccessConfigured = await app.healthKit.hasConfiguredAccess() }
            }
            .sheet(isPresented: $showRecoveryCompletion) {
                RecoveryCompletionModal(onDone: {
                    Task {
                        showRecoveryCompletion = false
                        // Now finalize on server and refresh global/profile state
                        if pendingLocalCompletion {
                            await app.game.pushRecoveryProgress()
                            await app.game.completeRecoveryIfEligible()
                            pendingLocalCompletion = false
                        }
                        await app.game.refreshFromServer()
                        await profileVM.refresh()
                    }
                })
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { handleForeground() }
            }
        }
    }

    private var content: some View {
        Group {
            switch selected {
            case .player: PlayerPanel(profile: profileVM.profile, areasMeta: areasVM.areas)
            case .habits: CombinedHabitsPanel(goodVM: goodVM, badVM: badVM, onAddGood: { showingAddGood = true }, onAddBad: { showingAddBad = true })
            case .areas: AreasPanel(vm: areasVM, onAdd: { showingAddArea = true }, header: EmptyView())
            case .store: StorePanel(vm: storeVM, header: EmptyView())
            case .archive: ArchivePanel(vm: archiveVM, onRestored: { await refreshAll() }, header: EmptyView())
            case .config: EmptyView()
            }
        }
    }

}

extension HabitsView {
    // Foreground refresh for recovery progress and server state
    @MainActor
    private func handleForeground() {
        Task {
            await app.game.refreshFromServer()
            if app.game.state == .recovery, await app.healthKit.hasConfiguredAccess() {
                await app.game.refreshDistance(using: app.healthKit)
                if app.game.recoveryDistance >= app.game.recoveryTarget {
                    pendingLocalCompletion = true
                    showRecoveryCompletion = true
                }
            }
        }
    }
    private func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await profileVM.refresh() }
            group.addTask { await areasVM.refresh() }
            group.addTask { await goodVM.refresh() }
            group.addTask { await badVM.refresh() }
            group.addTask { await storeVM.refresh() }
            group.addTask { await archiveVM.refresh() }
        }
    }

    private func onBadHabitRecorded() async {
        await refreshAll()
        await checkAndPresentGameOver()
    }

    private func checkAndPresentGameOver() async {
        if let life = profileVM.profile?.life {
            if life <= 0 {
                app.game.markLocalGameOverNow()
                await MainActor.run { showGameOverModal = true }
            } else {
                app.game.state = .active
                await MainActor.run { showGameOverModal = false }
            }
        }
    }
    
    private func handleHeaderSwipe(translation: CGFloat) {
        // Filter out config from navigation
        let navigableCases = SectionKind.allCases.filter { $0 != .config }
        guard let currentIndex = navigableCases.firstIndex(of: selected) else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if translation < -30 {
                // Swipe left - go to next
                let nextIndex = (currentIndex + 1) % navigableCases.count
                selected = navigableCases[nextIndex]
            } else if translation > 30 {
                // Swipe right - go to previous
                let previousIndex = currentIndex == 0 ? navigableCases.count - 1 : currentIndex - 1
                selected = navigableCases[previousIndex]
            }
        }
    }
    
    private func showSuccessToast(message: String) {
        withAnimation {
            toast = ToastMessage(message: message, type: .success)
        }
    }
    
    private func showErrorToast(message: String) {
        withAnimation {
            toast = ToastMessage(message: message, type: .error)
        }
    }
}

private struct LegacyPlayerHeader: View {
    @EnvironmentObject private var app: AppModel
    let profile: Profile?
    var onLogToday: () -> Void
    var onOpenStore: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                if let p = profile {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack { Text("Lvl \(p.level)").bold().padding(.horizontal, 6).padding(.vertical, 3).background(Capsule().fill(Color.blue.opacity(0.15))) }
                        let need = xpNeeded(level: p.level, base: p.xpPerLevel, curve: p.config?.levelCurve ?? "linear", multiplier: p.config?.levelMultiplier ?? 1.5)
                        ProgressView(value: Double(p.xp), total: Double(max(need,1))) {
                            HStack(spacing: 4) {
                                Text("XP")
                                Image(systemName: "arrow.right")
                                Text("\(p.xp)/\(need)")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 12) {
                            if app.game.state == .gameOver || p.life <= 0 {
                                Label("", systemImage: "skull")
                                    .foregroundStyle(.red)
                                    .font(.callout)
                            } else {
                                Label("\(p.life)/1000", systemImage: "heart.fill")
                                    .foregroundStyle(.red)
                                    .font(.callout)
                            }
                            Label("\(p.coins)", systemImage: "creditcard")
                                .font(.callout)
                        }
                        .labelStyle(.titleAndIcon)
                        Label("Streak N/A", systemImage: "flame")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                } else {
                    Text("Loading...")
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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
    var onConfig: (() -> Void)? = nil
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(HabitsView.SectionKind.allCases, id: \.self) { kind in
                    AnimatedPillButton(
                        kind: kind,
                        isSelected: selected == kind,
                        action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if kind == .config { 
                                    onConfig?() 
                                } else { 
                                    selected = kind 
                                }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 8)
        .background(
            Color.clear
                .contentShape(Rectangle())
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    handleSwipe(translation: value.translation.width)
                }
        )
    }
    
    private func handleSwipe(translation: CGFloat) {
        // Filter out config from navigation
        let navigableCases = HabitsView.SectionKind.allCases.filter { $0 != .config }
        guard let currentIndex = navigableCases.firstIndex(of: selected) else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if translation < -30 {
                // Swipe left - go to next
                let nextIndex = (currentIndex + 1) % navigableCases.count
                selected = navigableCases[nextIndex]
            } else if translation > 30 {
                // Swipe right - go to previous
                let previousIndex = currentIndex == 0 ? navigableCases.count - 1 : currentIndex - 1
                selected = navigableCases[previousIndex]
            }
        }
    }
}

private struct AnimatedPillButton: View {
    let kind: HabitsView.SectionKind
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: iconName(for: kind))
                    .font(.system(size: 16))
                    .frame(width: 20, height: 20)
                
                if isSelected {
                    Text(kind.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
            .padding(.horizontal, isSelected ? 16 : 12)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .animation(.easeInOut(duration: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(Text(kind.rawValue))
        .accessibilityAddTraits(.isButton)
    }
}

private func iconName(for kind: HabitsView.SectionKind) -> String {
    switch kind {
    case .player: return "person.crop.circle"
    case .habits: return "checkmark.circle"
    case .areas: return "square.grid.2x2"
    case .store: return "cart"
    case .archive: return "archivebox"
    case .config: return "gearshape"
    }
}

private struct PlayerHeaderWrapper<Content: View>: View {
    let profile: Profile?
    @Binding var selected: HabitsView.SectionKind
    var onConfig: () -> Void
    var content: () -> Content
    
    init(profile: Profile?, selected: Binding<HabitsView.SectionKind>, onConfig: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.profile = profile
        self._selected = selected
        self.onConfig = onConfig
        self.content = content
    }
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 0) {
                LegacyPlayerHeader(profile: profile, onLogToday: { selected = .habits }, onOpenStore: { selected = .store })
                TileNav(selected: $selected, onConfig: onConfig)
                content()
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

extension PlayerHeaderWrapper where Content == EmptyView {
    init(profile: Profile?, selected: Binding<HabitsView.SectionKind>, onConfig: @escaping () -> Void) {
        self.profile = profile
        self._selected = selected
        self.onConfig = onConfig
        self.content = { EmptyView() }
    }
}

private struct PlayerPanelList: View {
    @EnvironmentObject private var app: AppModel
    let profile: Profile?
    var areasMeta: [Area] = []
    var header: PlayerHeaderWrapper<EmptyView>
    
    var body: some View {
        List {
            if app.game.state == .gameOver {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(app.game.state == .recovery ? "Recovery in progress" : "Game Over")
                            .dsFont(.headerMD)
                        Text("Habit actions are disabled until you complete recovery.")
                            .dsFont(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .cardStyle()
                    .listRowBackground(Color.clear)
                }
            }
            header
            PlayerPanelContent(profile: profile, areasMeta: areasMeta)
        }
        .listStyle(.plain)
    }
}

private struct PlayerPanel: View {
    let profile: Profile?
    var areasMeta: [Area] = []
    var body: some View {
        PlayerPanelContent(profile: profile, areasMeta: areasMeta)
    }
}

private struct PlayerPanelContent: View {
    let profile: Profile?
    var areasMeta: [Area] = []
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                if let p = profile {
                    Text("Overall").dsFont(.headerMD)
                    HStack { Label("Life", systemImage: "heart.fill"); Spacer(); Text("\(p.life)") }
                    HStack { Label("Coins", systemImage: "creditcard"); Spacer(); Text("\(p.coins)") }
                    Divider()
                    Text("Per Area").dsFont(.headerMD)
                    ForEach(p.areas, id: \.areaId) { a in
                        VStack(alignment: .leading) {
                            HStack { Text(a.name).bold(); Spacer(); Text("Lvl \(a.level)") }
                            let meta = areasMeta.first(where: { $0.id == a.areaId })
                            let curve = meta?.levelCurve ?? "linear"
                            let mult = meta?.levelMultiplier ?? 1.5
                            let need = areaNeed(level: a.level, base: a.xpPerLevel, curve: curve, multiplier: mult)
                            let total = Double(max(need, 1))
                            let value = min(total, max(0, Double(a.xp)))
                            ProgressView(value: value, total: total) {
                                HStack(spacing: 6) {
                                    Text("XP to next")
                                    Image(systemName: "arrow.right")
                                    Text("\(a.xp) from \(need)")
                                }
                                .dsFont(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    Text("Loading stats...")
                }
            }
            .cardStyle()
        }
        .listRowBackground(Color.clear)
    }
}

private func areaNeed(level: Int, base: Int, curve: String, multiplier: Double) -> Int {
    if curve == "exp" {
        let m = max(1.0, multiplier)
        let powv = pow(m, Double(max(0, level - 1)))
        return max(1, Int(floor(Double(base) * powv)))
    } else { return max(1, base) }
}

private struct CombinedHabitsPanel: View {
    @ObservedObject var goodVM: HabitsViewModel
    @ObservedObject var badVM: BadHabitsViewModel
    var onAddGood: () -> Void
    var onAddBad: () -> Void
    @State private var editingGood: GoodHabit? = nil
    @State private var editingBad: BadHabit? = nil
    @State private var confirmDelete: (id: String, name: String)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                    Text("Good Habits").dsFont(.headerMD).bold()
                }
                ForEach(goodVM.habits) { habit in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack { Text(habit.name).dsFont(.headerMD); Spacer(); Text("XP +\(habit.xpReward) • Coins +\(habit.coinReward)").dsFont(.caption).foregroundStyle(.secondary) }
                        Button("Record") { Task { _ = await goodVM.complete(id: habit.id) } }
                            .buttonStyle(PrimaryButtonStyle())
                            .accessibilityLabel(Text("Complete habit \(habit.name)"))
                    }
                    .contentShape(Rectangle())
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button { editingGood = habit } label: { Label("Edit", systemImage: "pencil") }
                            .tint(.blue)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) { confirmDelete = (habit.id, habit.name) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
                Divider().padding(.vertical, 8)
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text("Bad Habits").dsFont(.headerMD).bold()
                }
                ForEach(badVM.items) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack { Text(item.name).dsFont(.headerMD); Spacer(); Text("Penalty \(item.lifePenalty)").dsFont(.caption).foregroundStyle(.secondary) }
                        Button("Record Slip") { Task { await badVM.record(id: item.id) } }
                            .buttonStyle(SecondaryButtonStyle())
                            .accessibilityLabel(Text("Record bad habit \(item.name)"))
                    }
                    .contentShape(Rectangle())
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button { editingBad = item } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) { confirmDelete = (item.id, item.name) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            .alert(item: Binding(get: {
                confirmDelete.map { ConfirmWrapper(id: $0.id, name: $0.name) }
            }, set: { newVal in
                if newVal == nil { confirmDelete = nil }
            })) { wrap in
                Alert(title: Text("Delete \(wrap.name)?"), message: Text("Are you sure you want to delete \(wrap.name)?"), primaryButton: .destructive(Text("Delete")) {
                    Task {
                        if goodVM.habits.contains(where: { $0.id == wrap.id }) { await goodVM.delete(id: wrap.id) }
                        else if badVM.items.contains(where: { $0.id == wrap.id }) { await badVM.delete(id: wrap.id) }
                    }
                }, secondaryButton: .cancel())
            }
            .sheet(item: $editingGood) { h in
                HabitDetailView(habit: h, onSave: { updated in Task { await goodVM.update(habit: updated) } }, onDelete: { Task { await goodVM.delete(id: h.id) } })
            }
            .sheet(item: $editingBad) { b in
                BadHabitDetailView(item: b, onSave: { updated in Task { await badVM.update(item: updated) } }, onDelete: { Task { await badVM.delete(id: b.id) } })
            }
        }
    }
}

// New body panels without headers for fixed header layout
private struct CombinedHabitsBodyPanel: View {
    @EnvironmentObject private var app: AppModel
    @ObservedObject var goodVM: HabitsViewModel
    @ObservedObject var badVM: BadHabitsViewModel
    var onRefresh: () async -> Void
    var onAddGood: () -> Void
    var onAddBad: () -> Void
    var onBadHabitRecorded: () async -> Void
    var onOpenRecovery: (Bool) -> Void
    var onShowSuccessToast: (String) -> Void
    var onShowErrorToast: (String) -> Void
    
    @State private var editingGood: GoodHabit? = nil
    @State private var editingBad: BadHabit? = nil
    @State private var confirmDelete: (id: String, name: String)? = nil
    @State private var inFlightIds: Set<String> = []
    
    var body: some View {
        List {
            Section {
                if goodVM.habits.isEmpty {
                    Text("No good habits yet").dsFont(.caption).foregroundStyle(.secondary)
                }
                ForEach(goodVM.habits) { habit in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack { Text(habit.name).dsFont(.headerMD); Spacer(); Text("XP +\(habit.xpReward) • Coins +\(habit.coinReward)").dsFont(.caption).foregroundStyle(.secondary) }
                    }
                    .cardStyle()
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            Task {
                                guard inFlightIds.contains(habit.id) == false else { return }
                                inFlightIds.insert(habit.id)
                                defer { inFlightIds.remove(habit.id) }
                                _ = await goodVM.complete(id: habit.id)
                                await onRefresh()
                                
                                // Show success toast
                                await MainActor.run {
                                    onShowSuccessToast("✅ \(habit.name) completed! +\(habit.xpReward) XP, +\(habit.coinReward) coins")
                                }
                            }
                        } label: { Label("Record", systemImage: "checkmark.circle.fill") }
                        .tint(.green)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button { editingGood = habit } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                        Button(role: .destructive) { confirmDelete = (habit.id, habit.name) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            } header: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                    Text("Good Habits").dsFont(.headerMD).bold()
                    Spacer()
                    Button { onAddGood() } label: { Image(systemName: "plus.circle.fill").foregroundStyle(.blue) }
                        .accessibilityLabel(Text("New Good Habit"))
                }
            }
            Section {
                if badVM.items.isEmpty {
                    Text("No bad habits yet").dsFont(.caption).foregroundStyle(.secondary)
                }
                ForEach(badVM.items) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack { Text(item.name).dsFont(.headerMD); Spacer(); Text("Penalty \(item.lifePenalty)").dsFont(.caption).foregroundStyle(.secondary) }
                    }
                    .cardStyle()
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            Task {
                                guard inFlightIds.contains(item.id) == false else { return }
                                inFlightIds.insert(item.id)
                                defer { inFlightIds.remove(item.id) }
                                if app.game.state != .active {
                                    let configured = await app.healthKit.hasConfiguredAccess()
                                    await MainActor.run { onOpenRecovery(configured) }
                                    if !configured {
                                        await MainActor.run {
                                            onShowErrorToast("Enable Health Access from Details to start recovery.")
                                        }
                                    }
                                    return
                                }
                                await badVM.record(id: item.id)
                                await onBadHabitRecorded()
                                
                                // Show warning toast
                                await MainActor.run {
                                    onShowErrorToast("⚠️ \(item.name) recorded. -\(item.lifePenalty) life")
                                }
                                if let e = badVM.apiError, e.status == 409 {
                                    await MainActor.run {
                                        onShowErrorToast("Game is not active. Start or continue recovery.")
                                    }
                                }
                            }
                        } label: { Label("Record", systemImage: "exclamationmark.circle") }
                        .tint(.red)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button { editingBad = item } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                        Button(role: .destructive) { confirmDelete = (item.id, item.name) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            } header: {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text("Bad Habits").dsFont(.headerMD).bold()
                    Spacer()
                    Button { onAddBad() } label: { Image(systemName: "plus.circle.fill").foregroundStyle(.red) }
                        .accessibilityLabel(Text("New Bad Habit"))
                }
            }
        }
        .listStyle(.plain)
        .refreshable { await onRefresh() }
        .alert(item: Binding(get: {
            confirmDelete.map { ConfirmWrapper(id: $0.id, name: $0.name) }
        }, set: { newVal in
            if newVal == nil { confirmDelete = nil }
        })) { wrap in
            Alert(title: Text("Delete \(wrap.name)?"), message: Text("Are you sure you want to delete \(wrap.name)?"), primaryButton: .destructive(Text("Delete")) {
                Task {
                    if goodVM.habits.contains(where: { $0.id == wrap.id }) { await goodVM.delete(id: wrap.id) }
                    else if badVM.items.contains(where: { $0.id == wrap.id }) { await badVM.delete(id: wrap.id) }
                    await onRefresh()
                }
            }, secondaryButton: .cancel())
        }
        .sheet(item: $editingGood) { h in
            HabitEditSheet(habit: h, onSave: { updated in Task { await goodVM.update(habit: updated); await onRefresh() } }, onDelete: { Task { await goodVM.delete(id: h.id); await onRefresh() } })
        }
        .sheet(item: $editingBad) { b in
            BadHabitEditSheet(item: b, onSave: { updated in Task { await badVM.update(item: updated); await onRefresh() } }, onDelete: { Task { await badVM.delete(id: b.id); await onRefresh() } })
        }
    }
}

// NOTE: Legacy CombinedHabitsListPanel removed to reduce compile complexity and duplication.
private struct ConfirmWrapper: Identifiable, Equatable {
    var id: String
    var name: String
}

// Toast types removed per request

// Body panels for fixed header layout
private struct AreasPanelBody: View {
    @ObservedObject var vm: AreasViewModel
    var onAdd: () -> Void
    @State private var editingArea: Area? = nil
    @State private var confirmDelete: (id: String, name: String)? = nil
    
    var body: some View {
        List {
            Section {
                ForEach(vm.areas) { area in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(area.icon ?? "🗂️")
                            Text(area.name).dsFont(.headerMD)
                            Spacer()
                            Text("XP/Level: \(area.xpPerLevel)")
                                .dsFont(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .cardStyle()
                    .listRowBackground(Color.clear)
                    .contentShape(Rectangle())
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button { editingArea = area } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                        Button(role: .destructive) { confirmDelete = (area.id, area.name) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            } header: {
                HStack {
                    Text("Areas").dsFont(.headerMD)
                    Spacer()
                    Button { onAdd() } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(.blue)
                    }
                    .accessibilityLabel(Text("New Area"))
                }
            }
        }
        .listStyle(.plain)
        .refreshable { await vm.refresh() }
        .alert(item: Binding(get: {
            confirmDelete.map { ConfirmWrapper(id: $0.id, name: $0.name) }
        }, set: { newVal in if newVal == nil { confirmDelete = nil } })) { wrap in
            Alert(title: Text("Delete \(wrap.name)?"), message: Text("Are you sure you want to delete \(wrap.name)?"), primaryButton: .destructive(Text("Delete")) {
                Task { await vm.delete(id: wrap.id) }
            }, secondaryButton: .cancel())
        }
        .sheet(item: $editingArea) { area in
            AreaEditSheet(area: area, onSave: { updated in Task { await vm.update(area: updated) } }, onDelete: { Task { await vm.delete(id: area.id) } })
        }
    }
}

private struct StorePanelBody: View {
    @ObservedObject var vm: StoreViewModel
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Bad Habits Store", systemImage: "cart").font(.headline)
                        Spacer()
                        HStack { Label("Coins", systemImage: "creditcard"); Text("\(vm.coins)") }
                            .dsFont(.caption)
                            .foregroundStyle(.secondary)
                    }
                    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(vm.controlledBadHabits) { b in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(b.name).dsFont(.headerMD)
                                Text("Penalty \(b.lifePenalty) • Cost \(b.coinCost)🪙").dsFont(.caption).foregroundStyle(.secondary)
                                Button { Task { await vm.buy(cosmeticId: b.id) } } label: { Label("Buy", systemImage: "cart") }
                                    .buttonStyle(PrimaryButtonStyle())
                                    .accessibilityLabel(Text("Buy \(b.name) for \(b.coinCost) coins"))
                            }
                            .cardStyle()
                        }
                    }
                    if !vm.ownedBadHabits.isEmpty {
                        Text("Owned (Credits)").dsFont(.headerMD)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(vm.ownedBadHabits, id: \.id) { obh in
                                HStack { Text(obh.name).dsFont(.body); Spacer(); Text("x\(obh.count)").dsFont(.caption) }
                                    .cardStyle()
                            }
                        }
                    }
                }
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .refreshable { await vm.refresh() }
    }
}

private struct ArchivePanelBody: View {
    @ObservedObject var vm: ArchiveViewModel
    var onRestored: () async -> Void
    @State private var inFlight: Set<String> = []

    var body: some View {
        List {
            if !vm.areas.isEmpty {
                Section("Areas") {
                    ForEach(vm.areas) { a in
                        HStack { Text(a.icon ?? "🗂️"); Text(a.name).dsFont(.headerMD); Spacer(); Text("XP/Level \(a.xpPerLevel)").dsFont(.caption).foregroundStyle(.secondary) }
                            .cardStyle()
                            .listRowBackground(Color.clear)
                            .swipeActions {
                                Button {
                                    Task { await vm.restoreArea(id: a.id); await vm.refresh(); await onRestored() }
                                } label: { Label("Restore", systemImage: "arrow.uturn.left.circle") }.tint(.green)
                            }
                    }
                }
            }
            if !vm.habits.isEmpty {
                Section("Habits") {
                    ForEach(vm.habits) { h in
                        HStack { Text(h.name).dsFont(.headerMD); Spacer(); Text("XP +\(h.xpReward) • Coins +\(h.coinReward)").dsFont(.caption).foregroundStyle(.secondary) }
                            .cardStyle()
                            .listRowBackground(Color.clear)
                            .swipeActions {
                                Button {
                                    Task { await vm.restoreHabit(id: h.id); await vm.refresh(); await onRestored() }
                                } label: { Label("Restore", systemImage: "arrow.uturn.left.circle") }.tint(.green)
                            }
                    }
                }
            }
            if !vm.badHabits.isEmpty {
                Section("Bad Habits") {
                    ForEach(vm.badHabits) { b in
                        HStack { Text(b.name).dsFont(.headerMD); Spacer(); Text("Penalty \(b.lifePenalty)").dsFont(.caption).foregroundStyle(.secondary) }
                            .cardStyle()
                            .listRowBackground(Color.clear)
                            .swipeActions {
                                Button {
                                    Task { await vm.restoreBadHabit(id: b.id); await vm.refresh(); await onRestored() }
                                } label: { Label("Restore", systemImage: "arrow.uturn.left.circle") }.tint(.green)
                            }
                    }
                }
            }
            if vm.areas.isEmpty && vm.habits.isEmpty && vm.badHabits.isEmpty {
                Section { Text("Archive is empty.").foregroundStyle(.secondary) }
            }
        }
        .listStyle(.plain)
        .task { await vm.refresh() }
        .refreshable { await vm.refresh() }
    }
}

private struct PlayerPanelBody: View {
    let profile: Profile?
    var areasMeta: [Area] = []
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    if let p = profile {
                        Text("Overall").dsFont(.headerMD)
                        HStack { Label("Life", systemImage: "heart.fill"); Spacer(); Text("\(p.life)") }
                        HStack { Label("Coins", systemImage: "creditcard"); Spacer(); Text("\(p.coins)") }
                        Divider()
                        Text("Per Area").dsFont(.headerMD)
                        ForEach(p.areas, id: \.areaId) { a in
                            VStack(alignment: .leading) {
                                HStack { Text(a.name).bold(); Spacer(); Text("Lvl \(a.level)") }
                                let meta = areasMeta.first(where: { $0.id == a.areaId })
                                let curve = meta?.levelCurve ?? "linear"
                                let mult = meta?.levelMultiplier ?? 1.5
                                let need = areaNeed(level: a.level, base: a.xpPerLevel, curve: curve, multiplier: mult)
                                let total = Double(max(need, 1))
                                let value = min(total, max(0, Double(a.xp)))
                                ProgressView(value: value, total: total) {
                                    HStack(spacing: 6) {
                                        Text("XP to next")
                                        Image(systemName: "arrow.right")
                                        Text("\(a.xp) from \(need)")
                                    }
                                    .dsFont(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else {
                        Text("Loading stats...")
                    }
                }
                .cardStyle()
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
    }
}

// Original panels with headers (kept for compatibility)
private struct AreasPanel<Header: View>: View {
    @ObservedObject var vm: AreasViewModel
    var onAdd: () -> Void
    var header: Header
    @State private var editingArea: Area? = nil
    @State private var confirmDelete: (id: String, name: String)? = nil
    
    var body: some View {
        List {
            if !(header is EmptyView) {
                header
            }
            Section {
                ForEach(vm.areas) { area in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(area.icon ?? "🗂️")
                            Text(area.name).dsFont(.headerMD)
                            Spacer()
                            Text("XP/Level: \(area.xpPerLevel)")
                                .dsFont(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .cardStyle()
                    .listRowBackground(Color.clear)
                    .contentShape(Rectangle())
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button { editingArea = area } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                        Button(role: .destructive) { confirmDelete = (area.id, area.name) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            } header: {
                HStack {
                    Text("Areas").dsFont(.headerMD)
                    Spacer()
                    Button { onAdd() } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(.blue)
                    }
                    .accessibilityLabel(Text("New Area"))
                }
            }
        }
        .listStyle(.plain)
        .alert(item: Binding(get: {
            confirmDelete.map { ConfirmWrapper(id: $0.id, name: $0.name) }
        }, set: { newVal in if newVal == nil { confirmDelete = nil } })) { wrap in
            Alert(title: Text("Delete \(wrap.name)?"), message: Text("Are you sure you want to delete \(wrap.name)?"), primaryButton: .destructive(Text("Delete")) {
                Task { await vm.delete(id: wrap.id) }
            }, secondaryButton: .cancel())
        }
        .sheet(item: $editingArea) { area in
            AreaEditSheet(area: area, onSave: { updated in Task { await vm.update(area: updated) } }, onDelete: { Task { await vm.delete(id: area.id) } })
        }
    }
}

private struct StorePanel<Header: View>: View {
    @ObservedObject var vm: StoreViewModel
    var header: Header
    
    var body: some View {
        List {
            if !(header is EmptyView) {
                header
            }
            Section {
                VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Bad Habits Store", systemImage: "cart").font(.headline)
                    Spacer()
                    HStack { Label("Coins", systemImage: "creditcard"); Text("\(vm.coins)") }
                        .dsFont(.caption)
                        .foregroundStyle(.secondary)
                }
                let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(vm.controlledBadHabits) { b in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(b.name).dsFont(.headerMD)
                            Text("Penalty \(b.lifePenalty) • Cost \(b.coinCost)🪙").dsFont(.caption).foregroundStyle(.secondary)
                            Button { Task { await vm.buy(cosmeticId: b.id) } } label: { Label("Buy", systemImage: "cart") }
                                .buttonStyle(PrimaryButtonStyle())
                                .accessibilityLabel(Text("Buy \(b.name) for \(b.coinCost) coins"))
                        }
                        .cardStyle()
                    }
                }
                if !vm.ownedBadHabits.isEmpty {
                    Text("Owned (Credits)").dsFont(.headerMD)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(vm.ownedBadHabits, id: \.id) { obh in
                            HStack { Text(obh.name).dsFont(.body); Spacer(); Text("x\(obh.count)").dsFont(.caption) }
                                .cardStyle()
                        }
                    }
                }
            }
        }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
    }
}

private struct ArchivePanel<Header: View>: View {
    @ObservedObject var vm: ArchiveViewModel
    var onRestored: () async -> Void
    var header: Header
    @State private var inFlight: Set<String> = []

    var body: some View {
        List {
            if !(header is EmptyView) {
                header
            }
            if !vm.areas.isEmpty {
                Section("Areas") {
                    ForEach(vm.areas) { a in
                        HStack { Text(a.icon ?? "🗂️"); Text(a.name).dsFont(.headerMD); Spacer(); Text("XP/Level \(a.xpPerLevel)").dsFont(.caption).foregroundStyle(.secondary) }
                            .cardStyle()
                            .listRowBackground(Color.clear)
                            .swipeActions {
                                Button {
                                    Task { await vm.restoreArea(id: a.id); await vm.refresh(); await onRestored() }
                                } label: { Label("Restore", systemImage: "arrow.uturn.left.circle") }.tint(.green)
                            }
                    }
                }
            }
            if !vm.habits.isEmpty {
                Section("Habits") {
                    ForEach(vm.habits) { h in
                        HStack { Text(h.name).dsFont(.headerMD); Spacer(); Text("XP +\(h.xpReward) • Coins +\(h.coinReward)").dsFont(.caption).foregroundStyle(.secondary) }
                            .cardStyle()
                            .listRowBackground(Color.clear)
                            .swipeActions {
                                Button {
                                    Task { await vm.restoreHabit(id: h.id); await vm.refresh(); await onRestored() }
                                } label: { Label("Restore", systemImage: "arrow.uturn.left.circle") }.tint(.green)
                            }
                    }
                }
            }
            if !vm.badHabits.isEmpty {
                Section("Bad Habits") {
                    ForEach(vm.badHabits) { b in
                        HStack { Text(b.name).dsFont(.headerMD); Spacer(); Text("Penalty \(b.lifePenalty)").dsFont(.caption).foregroundStyle(.secondary) }
                            .cardStyle()
                            .listRowBackground(Color.clear)
                            .swipeActions {
                                Button {
                                    Task { await vm.restoreBadHabit(id: b.id); await vm.refresh(); await onRestored() }
                                } label: { Label("Restore", systemImage: "arrow.uturn.left.circle") }.tint(.green)
                            }
                    }
                }
            }
            if vm.areas.isEmpty && vm.habits.isEmpty && vm.badHabits.isEmpty {
                Section { Text("Archive is empty.").foregroundStyle(.secondary) }
            }
        }
        .listStyle(.plain)
        .task { await vm.refresh() }
        .refreshable { await vm.refresh() }
    }
}

struct NewHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    let areas: [Area]
    @State private var selectedAreaId: String = ""
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
                    Picker("Area", selection: $selectedAreaId) {
                        ForEach(areas, id: \.id) { a in
                            Text(a.name).tag(a.id)
                        }
                    }
                    TextField("Name", text: $name)
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
                ToolbarItem(placement: .confirmationAction) { Button("Create") { onCreate(selectedAreaId, name, xp, coins, cadence.isEmpty ? nil : cadence, active); dismiss() }.buttonStyle(PrimaryButtonStyle()).disabled(name.isEmpty || selectedAreaId.isEmpty) }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            if selectedAreaId.isEmpty, let first = areas.first { selectedAreaId = first.id }
        }
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
                }.buttonStyle(PrimaryButtonStyle())
                Button("Delete", role: .destructive) { onDelete(); dismiss() }
            }
        }
        .navigationTitle("Edit Habit")
    }
}

struct NewBadHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    let areas: [Area]
    @State private var selectedAreaId: String = "" // empty is Global
    @State private var name: String = ""
    @State private var lifePenaltyInput: String = "5"
    @State private var controllable: Bool = false
    @State private var coinCost: Int = 0
    @State private var active: Bool = true

    var onCreate: (String, String, Int, Bool, Int, Bool) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    Picker("Area", selection: $selectedAreaId) {
                        Text("None (Global)").tag("")
                        ForEach(areas, id: \.id) { a in
                            Text(a.name).tag(a.id)
                        }
                    }
                    TextField("Name", text: $name)
                    Toggle("Controllable", isOn: $controllable)
                    Toggle("Active", isOn: $active)
                }
                Section("Penalty / Cost") {
                    TextField("Life Penalty (1-1000)", text: $lifePenaltyInput)
                        .keyboardType(.numberPad)
                    Stepper("Coin Cost: \(coinCost)", value: $coinCost, in: 0...100)
                }
            }
            .navigationTitle("New Bad Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let penalty = max(1, min(1000, Int(lifePenaltyInput) ?? 5))
                        onCreate(selectedAreaId, name, penalty, controllable, coinCost, active)
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(name.isEmpty)
                }
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
                // Life Penalty (1-1000) as text input for easier editing
                HStack {
                    Text("Life Penalty")
                    Spacer()
                    TextField("1-1000", value: $item.lifePenalty, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: item.lifePenalty) { _, newVal in
                            item.lifePenalty = max(1, min(1000, newVal))
                        }
                }
                Stepper("Coin Cost: \(item.coinCost)", value: $item.coinCost, in: 0...100)
            }
            Section {
                Button("Save") {
                    let updated = BadHabit(id: item.id, areaId: areaIdInput.isEmpty ? nil : areaIdInput, name: item.name, lifePenalty: item.lifePenalty, controllable: item.controllable, coinCost: item.coinCost, isActive: item.isActive)
                    onSave(updated); dismiss()
                }.buttonStyle(PrimaryButtonStyle())
                Button("Delete", role: .destructive) { onDelete(); dismiss() }
            }
        }
        .navigationTitle("Edit Bad Habit")
    }
}
