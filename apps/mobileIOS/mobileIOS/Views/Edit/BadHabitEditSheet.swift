import SwiftUI

struct BadHabitEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var app: AppModel

    @State private var item: BadHabit
    @State private var areas: [Area] = []
    @State private var selectedAreaId: String // empty => Global
    var onSave: (BadHabit) -> Void
    var onDelete: () -> Void

    init(item: BadHabit, onSave: @escaping (BadHabit) -> Void, onDelete: @escaping () -> Void) {
        _item = State(initialValue: item)
        _selectedAreaId = State(initialValue: item.areaId ?? "")
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    Picker("Area", selection: $selectedAreaId) {
                        Text("None (Global)").tag("")
                        ForEach(areas, id: \.id) { a in
                            Text(a.name).tag(a.id)
                        }
                    }
                    TextField("Name", text: $item.name)
                    // Controllable removed from UI. Keep server value.
                    Toggle("Active", isOn: $item.isActive)
                }
                Section("Costs") {
                    Stepper("Life Penalty: \(item.lifePenalty)", value: $item.lifePenalty, in: 1...100)
                    Stepper("Coin Cost: \(item.coinCost)", value: $item.coinCost, in: 0...100)
                }
                Section { Button("Delete", role: .destructive) { onDelete(); dismiss() } }
            }
            .navigationTitle("Edit Bad Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updated = BadHabit(id: item.id,
                                               areaId: selectedAreaId.isEmpty ? nil : selectedAreaId,
                                               name: item.name,
                                               lifePenalty: item.lifePenalty,
                                               controllable: item.controllable,
                                               coinCost: item.coinCost,
                                               isActive: item.isActive)
                        onSave(updated); dismiss()
                    }.keyboardShortcut(.defaultAction)
                }
            }
        }
        .task { await loadAreas() }
    }

    private func loadAreas() async {
        do {
            let fetched: [Area] = try await app.api.get("areas")
            areas = fetched
            if !selectedAreaId.isEmpty, areas.first(where: { $0.id == selectedAreaId }) == nil {
                selectedAreaId = ""
            }
        } catch {
            // Best-effort; leave picker empty if fetch fails
        }
    }
}
