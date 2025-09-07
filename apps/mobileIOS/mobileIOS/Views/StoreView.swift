import SwiftUI

struct StoreView: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var vm: StoreViewModel

    init() {
        let app = AppModel()
        _vm = StateObject(wrappedValue: StoreViewModel(api: app.api))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Wallet") {
                    LabeledContent("Coins", value: "\(vm.coins)")
                }

                Section("Controlled Bad Habits Store") {
                    if vm.controlledBadHabits.isEmpty { Text("None available") }
                    ForEach(vm.controlledBadHabits) { b in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(b.name).font(.headline)
                                Text("Penalty \(b.lifePenalty) • Cost \(b.coinCost)🪙").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            let owned = vm.ownedBadHabits.contains(where: { $0.id == b.id })
                            Button(owned ? "Owned" : "Buy") { Task { await vm.buy(cosmeticId: b.id) } }
                                .buttonStyle(.borderedProminent)
                                .disabled(owned)
                        }
                    }
                }

                Section("Owned Bad Habits") {
                    if vm.ownedBadHabits.isEmpty { Text("You don't own any yet") }
                    ForEach(vm.ownedBadHabits, id: \.id) { obh in
                        Text(obh.name)
                    }
                }
            }
            .navigationTitle("Store")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { Task { await vm.refresh() } } label: { Image(systemName: "arrow.clockwise") } } }
            .task { await vm.refresh() }
            .refreshable { await vm.refresh() }
            .alert(item: $vm.apiError) { err in Alert(title: Text("Error"), message: Text(err.message), dismissButton: .default(Text("OK"))) }
        }
    }
}

