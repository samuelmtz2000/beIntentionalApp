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

                Section("Cosmetics Store") {
                    if vm.cosmetics.isEmpty { Text("No cosmetics available") }
                    ForEach(vm.cosmetics) { cos in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(cos.key.capitalized).font(.headline)
                                Text(cos.category.capitalized).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(cos.price)🪙").font(.subheadline)
                            Button(vm.ownedKeys.contains(cos.key) ? "Owned" : "Buy") {
                                Task { await vm.buy(cosmeticId: cos.id) }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(vm.ownedKeys.contains(cos.key))
                        }
                    }
                }

                Section("Your Items") {
                    if vm.ownedKeys.isEmpty { Text("You don't own any cosmetics yet") }
                    ForEach(Array(vm.ownedKeys), id: \.self) { key in
                        HStack {
                            Text(key.capitalized)
                            Spacer()
                            if vm.selectedKey == key { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                            Button(vm.selectedKey == key ? "Using" : "Use") { vm.use(key: key) }
                                .buttonStyle(.bordered)
                                .disabled(vm.selectedKey == key)
                        }
                    }
                }

                Section("Controlled Bad Habits") {
                    if vm.controlledBadHabits.isEmpty { Text("None available") }
                    ForEach(vm.controlledBadHabits) { b in
                        VStack(alignment: .leading) {
                            Text(b.name).font(.headline)
                            Text("Cost: \(b.coinCost)🪙 • Penalty \(b.lifePenalty)").font(.caption).foregroundStyle(.secondary)
                        }
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

