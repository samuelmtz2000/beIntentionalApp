import SwiftUI

struct HabitEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var app: AppModel

    @State private var habit: GoodHabit
    @State private var areas: [Area] = []
    @State private var selectedAreaId: String
    var onSave: (GoodHabit) -> Void
    var onDelete: () -> Void

    init(habit: GoodHabit, onSave: @escaping (GoodHabit) -> Void, onDelete: @escaping () -> Void) {
        _habit = State(initialValue: habit)
        _selectedAreaId = State(initialValue: habit.areaId)
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    Picker("Area", selection: $selectedAreaId) {
                        ForEach(areas, id: \.id) { a in
                            Text(a.name).tag(a.id)
                        }
                    }
                    TextField("Name", text: $habit.name)
                    TextField("Cadence", text: Binding(get: { habit.cadence ?? "" }, set: { habit.cadence = $0.isEmpty ? nil : $0 }))
                    Toggle("Active", isOn: $habit.isActive)
                }
                Section("Rewards") {
                    Stepper("XP: \(habit.xpReward)", value: $habit.xpReward, in: 1...1000)
                    Stepper("Coins: \(habit.coinReward)", value: $habit.coinReward, in: 0...1000)
                }
                Section { Button("Delete", role: .destructive) { onDelete(); dismiss() } }
            }
            .navigationTitle("Edit Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updated = GoodHabit(id: habit.id, areaId: selectedAreaId, name: habit.name, xpReward: habit.xpReward, coinReward: habit.coinReward, cadence: habit.cadence, isActive: habit.isActive)
                        onSave(updated); dismiss()
                    }.buttonStyle(PrimaryButtonStyle()).keyboardShortcut(.defaultAction)
                }
            }
        }
        .task { await loadAreas() }
    }

    private func loadAreas() async {
        do {
            let fetched: [Area] = try await app.api.get("areas")
            areas = fetched
            if areas.first(where: { $0.id == selectedAreaId }) == nil, let first = areas.first { selectedAreaId = first.id }
        } catch {
            // Best-effort; leave picker empty if fetch fails
        }
    }
}
