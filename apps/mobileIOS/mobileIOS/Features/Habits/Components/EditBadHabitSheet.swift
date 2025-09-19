//
//  EditBadHabitSheet.swift
//  mobileIOS
//

import SwiftUI

struct EditBadHabitSheet: View {
    let habit: BadHabit
    let areas: [Area]
    let onSave: (BadHabit) async -> Void

    @State private var selectedAreaId: String
    @State private var name: String
    @State private var lifePenalty: String
    @State private var controllable: Bool
    @State private var coinCost: String
    @State private var isActive: Bool
    @State private var isGlobalHabit: Bool

    @Environment(\.dismiss) private var dismiss

    init(habit: BadHabit, areas: [Area], onSave: @escaping (BadHabit) async -> Void) {
        self.habit = habit
        self.areas = areas
        self.onSave = onSave
        _selectedAreaId = State(initialValue: habit.areaId ?? (areas.first?.id ?? ""))
        _name = State(initialValue: habit.name)
        _lifePenalty = State(initialValue: String(habit.lifePenalty))
        _controllable = State(initialValue: habit.controllable)
        _coinCost = State(initialValue: String(habit.coinCost))
        _isActive = State(initialValue: habit.isActive)
        _isGlobalHabit = State(initialValue: habit.areaId == nil)
    }

    var body: some View {
        DSSheet(
            title: "Edit Bad Habit",
            onCancel: { dismiss() },
            onSave: {
                var updated = habit
                updated = BadHabit(id: habit.id, areaId: isGlobalHabit ? nil : selectedAreaId, name: name, lifePenalty: Int(lifePenalty) ?? habit.lifePenalty, controllable: controllable, coinCost: Int(coinCost) ?? habit.coinCost, isActive: isActive)
                await onSave(updated)
                dismiss()
            },
            canSave: isFormValid
        ) {
            VStack(spacing: 16) {
                DSToggleField(label: "Global Habit", isOn: $isGlobalHabit, helpText: "Global habits are not tied to a specific area")
                if !isGlobalHabit {
                    DSPickerField(label: "Area", selection: $selectedAreaId, options: areas.map { $0.id }, displayName: { id in areas.first { $0.id == id }?.name ?? "Unknown" })
                }
                DSFormField(label: "Habit Name", text: $name, placeholder: "e.g., Junk food")
                DSFormField(label: "Life Penalty", text: $lifePenalty, placeholder: "5", keyboardType: .numberPad)
                DSToggleField(label: "Controllable", isOn: $controllable, helpText: "Use coins to avoid penalty")
                if controllable {
                    DSFormField(label: "Coin Cost", text: $coinCost, placeholder: "10", keyboardType: .numberPad)
                }
                DSToggleField(label: "Active", isOn: $isActive, helpText: "Active habits are shown in the list")
            }
        }
    }

    private var isFormValid: Bool {
        let penalty = Int(lifePenalty) ?? 0
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        penalty > 0 && (!controllable || (Int(coinCost) ?? 0) > 0)
    }
}

