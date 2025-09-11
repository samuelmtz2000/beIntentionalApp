import SwiftUI

struct StoreView: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var vm: StoreViewModel

    init() {
        let app = AppModel()
        _vm = StateObject(wrappedValue: StoreViewModel(api: app.api))
    }

    @Environment(\.colorScheme) private var scheme
    var body: some View {
        NavigationStack {
            List {
                WalletSection(coins: vm.coins)
                StoreBadHabitsSection(items: vm.controlledBadHabits, ownedCount: { id in ownedCount(id) }) { id in
                    Task { await vm.buy(cosmeticId: id) }
                }
                OwnedBadHabitsSection(items: vm.ownedBadHabits)
            }
            .navigationTitle("Store")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { Task { await vm.refresh() } } label: { Image(systemName: "arrow.clockwise") } } }
            .task { await vm.refresh() }
            .refreshable { await vm.refresh() }
            .alert(item: $vm.apiError) { err in Alert(title: Text("Error"), message: Text(err.message), dismissButton: .default(Text("OK"))) }
        }
        .background(DSTheme.colors(for: scheme).backgroundPrimary)
        .toolbarBackground(DSTheme.colors(for: scheme).backgroundSecondary, for: .navigationBar)
        .toolbarColorScheme(scheme, for: .navigationBar)
    }

    private func ownedCount(_ id: String) -> Int { vm.ownedBadHabits.first(where: { $0.id == id })?.count ?? 0 }
}

private struct WalletSection: View {
    let coins: Int
    var body: some View {
        Section("Wallet") { LabeledContent("Coins", value: "\(coins)") }
    }
}

private struct StoreBadHabitsSection: View {
    let items: [BadHabit]
    let ownedCount: (String) -> Int
    let onBuy: (String) -> Void
    var body: some View {
        Section("Bad Habits Store") {
            if items.isEmpty {
                Text("None available")
            } else {
                ForEach(items) { b in
                    BadHabitStoreRow(item: b, ownedCount: ownedCount(b.id)) { onBuy(b.id) }
                }
            }
        }
    }
}

private struct BadHabitStoreRow: View {
    let item: BadHabit
    let ownedCount: Int
    let onBuy: () -> Void
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name).dsFont(.headerMD)
                Text("Penalty \(item.lifePenalty) • Cost \(item.coinCost)🪙").dsFont(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if ownedCount > 0 { Text("Owned: \(ownedCount)").dsFont(.caption) }
            Button("Buy", action: onBuy)
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityLabel(Text("Buy \(item.name) for \(item.coinCost) coins"))
        }
        .cardStyle()
        .listRowBackground(Color.clear)
    }
}

private struct OwnedBadHabitsSection: View {
    let items: [OwnedBadHabit]
    var body: some View {
        Section("Owned Bad Habits (Credits)") {
            if items.isEmpty {
                Text("You don't own any yet")
            } else {
                ForEach(items, id: \.id) { obh in
                    HStack { Text(obh.name); Spacer(); Text("x\(obh.count)").font(.caption) }
                }
            }
        }
    }
}
