import SwiftUI

struct AreasView: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var vm: AreasViewModel
    @State private var showingAdd = false

    init() {
        let app = AppModel()
        _vm = StateObject(wrappedValue: AreasViewModel(api: app.api))
    }

    @Environment(\.colorScheme) private var scheme
    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.areas) { area in
                    NavigationLink(destination: AreaDetailView(area: area) { updated in
                        Task { await vm.update(area: updated) }
                    } onDelete: {
                        Task { await vm.delete(id: area.id) }
                    }) {
                        HStack {
                            Text(area.icon ?? "🗂️")
                            Text(area.name)
                            Spacer()
                            Text("XP/Level: \(area.xpPerLevel)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions { Button(role: .destructive) { Task { await vm.delete(id: area.id) } } label: { Label("Delete", systemImage: "trash") } }
                }
            }
            .navigationTitle("Areas")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button { showingAdd = true } label: { Image(systemName: "plus") } }
                ToolbarItem(placement: .navigationBarTrailing) { Button { Task { await vm.refresh() } } label: { Image(systemName: "arrow.clockwise") } }
            }
            .sheet(isPresented: $showingAdd) { NewAreaSheet { name, icon, xp, curve, mult in
                Task { await vm.create(name: name, icon: icon, xpPerLevel: xp, levelCurve: curve, levelMultiplier: mult) }
            } }
            .task { await vm.refresh() }
            .alert(item: $vm.apiError) { err in Alert(title: Text("Error"), message: Text(err.message), dismissButton: .default(Text("OK"))) }
        }
        .background(DSTheme.colors(for: scheme).backgroundPrimary)
    }
}

struct NewAreaSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var icon: String = ""
    @State private var xpPerLevel: Int = 100
    @State private var levelCurve: String = "linear"
    @State private var levelMultiplier: Double = 1.5

    var onCreate: (String, String?, Int, String, Double?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name", text: $name)
                    TextField("Icon (emoji)", text: $icon)
                    Picker("Curve", selection: $levelCurve) {
                        Text("Linear").tag("linear")
                        Text("Exp").tag("exp")
                    }.pickerStyle(.segmented)
                }
                Section("XP") {
                    Stepper("XP per Level: \(xpPerLevel)", value: $xpPerLevel, in: 10...1000)
                    if levelCurve == "exp" {
                        HStack { Text("Multiplier"); Spacer(); Text(String(format: "%.2f×", levelMultiplier)).foregroundStyle(.secondary) }
                        Slider(value: $levelMultiplier, in: 1.0...4.0, step: 0.1)
                        Text("Each level requires multiplier× previous XP.").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New Area")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Create") { onCreate(name, icon.isEmpty ? nil : icon, xpPerLevel, levelCurve, levelCurve == "exp" ? levelMultiplier : nil); dismiss() }.buttonStyle(PrimaryButtonStyle()).disabled(name.isEmpty) }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct AreaDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State var area: Area
    var onSave: (Area) -> Void
    var onDelete: () -> Void

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Name", text: $area.name)
                TextField("Icon", text: Binding(get: { area.icon ?? "" }, set: { area.icon = $0.isEmpty ? nil : $0 }))
                Picker("Curve", selection: $area.levelCurve) { Text("Linear").tag("linear"); Text("Exp").tag("exp") }.pickerStyle(.segmented)
            }
            Section("XP") {
                Stepper("XP per Level: \(area.xpPerLevel)", value: $area.xpPerLevel, in: 10...1000)
            }
            Section {
                Button("Save") { onSave(area); dismiss() }.buttonStyle(.borderedProminent)
                Button("Delete", role: .destructive) { onDelete(); dismiss() }
            }
        }
        .navigationTitle("Edit Area")
    }
}
