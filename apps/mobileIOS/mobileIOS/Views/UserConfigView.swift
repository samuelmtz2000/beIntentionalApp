import SwiftUI

struct UserConfigSheet: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: UserConfigViewModel
    var onSaved: () -> Void

    init(onSaved: @escaping () -> Void) {
        self.onSaved = onSaved
        let app = AppModel()
        _vm = StateObject(wrappedValue: UserConfigViewModel(api: app.api))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Global Leveling") {
                    Stepper("XP per Level: \(vm.xpPerLevel)", value: $vm.xpPerLevel, in: 10...10000, step: 5)
                    Picker("Curve", selection: $vm.levelCurve) {
                        Text("Linear").tag("linear")
                        Text("Exponential").tag("exp")
                    }.pickerStyle(.segmented)
                    if vm.levelCurve == "exp" {
                        HStack { Text("Multiplier"); Spacer(); Text(String(format: "%.2f×", vm.levelMultiplier)).foregroundStyle(.secondary) }
                        Slider(value: $vm.levelMultiplier, in: 1.0...4.0, step: 0.1)
                        Text("Each level requires multiplier× previous XP.").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("XP Source Mode") {
                    Picker("Computation", selection: $vm.xpComputationMode) {
                        Text("From Logs").tag("logs")
                        Text("Stored").tag("stored")
                    }.pickerStyle(.segmented)
                    Text("Logs: sums past habit completions. Stored: increments a counter on completion.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("User Config")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button(vm.isSaving ? "Saving…" : "Save") { Task { if await vm.save() { onSaved(); dismiss() } } }.disabled(vm.isSaving) }
            }
            .task { await vm.load() }
            .alert(item: $vm.apiError) { err in Alert(title: Text("Error"), message: Text(err.message), dismissButton: .default(Text("OK"))) }
        }
    }
}

