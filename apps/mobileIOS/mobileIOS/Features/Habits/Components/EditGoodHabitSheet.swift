//
//  EditGoodHabitSheet.swift
//  mobileIOS
//

import SwiftUI

struct EditGoodHabitSheet: View {
    let habit: GoodHabit
    let areas: [Area]
    let onSave: (GoodHabit) async -> Void

    @State private var selectedAreaId: String
    @State private var name: String
    @State private var xpReward: String
    @State private var coinReward: String
    @State private var cadence: String
    @State private var isActive: Bool

    @Environment(\.dismiss) private var dismiss

    init(habit: GoodHabit, areas: [Area], onSave: @escaping (GoodHabit) async -> Void) {
        self.habit = habit
        self.areas = areas
        self.onSave = onSave
        _selectedAreaId = State(initialValue: habit.areaId)
        _name = State(initialValue: habit.name)
        _xpReward = State(initialValue: String(habit.xpReward))
        _coinReward = State(initialValue: String(habit.coinReward))
        _cadence = State(initialValue: habit.cadence ?? "")
        _isActive = State(initialValue: habit.isActive)
    }

    var body: some View {
        DSSheet(
            title: "Edit Good Habit",
            onCancel: { dismiss() },
            onSave: {
                var updated = habit
                updated = GoodHabit(id: habit.id, areaId: selectedAreaId, name: name, xpReward: Int(xpReward) ?? habit.xpReward, coinReward: Int(coinReward) ?? habit.coinReward, cadence: cadence.isEmpty ? nil : cadence, isActive: isActive)
                await onSave(updated)
                dismiss()
            },
            canSave: isFormValid
        ) {
            VStack(spacing: 16) {
                DSPickerField(
                    label: "Area",
                    selection: $selectedAreaId,
                    options: areas.map { $0.id },
                    displayName: { id in areas.first { $0.id == id }?.name ?? "Unknown" }
                )
                DSFormField(label: "Habit Name", text: $name, placeholder: "e.g., Morning meditation")
                DSFormField(label: "XP Reward", text: $xpReward, placeholder: "10", keyboardType: .numberPad)
                DSFormField(label: "Coin Reward", text: $coinReward, placeholder: "5", keyboardType: .numberPad)
                DSFormField(label: "Cadence (Optional)", text: $cadence, placeholder: "e.g., Daily, Weekly")
                DSToggleField(label: "Active", isOn: $isActive, helpText: "Active habits will be shown in your habits list")
            }
        }
    }

    private var isFormValid: Bool {
        !selectedAreaId.isEmpty && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

