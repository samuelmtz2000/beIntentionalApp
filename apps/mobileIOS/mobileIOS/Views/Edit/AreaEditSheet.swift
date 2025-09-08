import SwiftUI

struct AreaEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var area: Area
    var onSave: (Area) -> Void
    var onDelete: () -> Void

    init(area: Area, onSave: @escaping (Area) -> Void, onDelete: @escaping () -> Void) {
        _area = State(initialValue: area)
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name", text: $area.name)
                    TextField("Icon (emoji)", text: Binding(get: { area.icon ?? "" }, set: { area.icon = $0.isEmpty ? nil : $0 }))
                    Stepper("XP per Level: \(area.xpPerLevel)", value: $area.xpPerLevel, in: 10...10000)
                    Picker("Curve", selection: $area.levelCurve) {
                        Text("Linear").tag("linear")
                        Text("Exponential").tag("exp")
                    }.pickerStyle(.segmented)
                }
                Section {
                    Button("Save") { onSave(area); dismiss() }
                        .buttonStyle(.borderedProminent)
                    Button("Delete", role: .destructive) { onDelete(); dismiss() }
                }
            }
            .navigationTitle("Edit Area")
        }
    }
}

