//
//  AddGoodHabitSheet.swift
//  mobileIOS
//
//  Sheet for adding a new good habit using consistent form patterns
//

import SwiftUI

struct AddGoodHabitSheet: View {
    let areas: [Area]
    let onSave: (String, String, Int, Int, String?, Bool) async -> Void
    
    @State private var selectedAreaId = ""
    @State private var name = ""
    @State private var xpReward = "10"
    @State private var coinReward = "5"
    @State private var cadence = ""
    @State private var isActive = true
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        DSSheet(
            title: "New Good Habit",
            onCancel: { dismiss() },
            onSave: {
                await onSave(
                    selectedAreaId,
                    name,
                    Int(xpReward) ?? 10,
                    Int(coinReward) ?? 5,
                    cadence.isEmpty ? nil : cadence,
                    isActive
                )
                dismiss()
            },
            canSave: isFormValid
        ) {
            VStack(spacing: 16) {
                // Area selection
                DSPickerField(
                    label: "Area",
                    selection: $selectedAreaId,
                    options: areas.map { $0.id },
                    displayName: { id in
                        areas.first { $0.id == id }?.name ?? "Unknown"
                    }
                )
                
                // Habit name
                DSFormField(
                    label: "Habit Name",
                    text: $name,
                    placeholder: "e.g., Morning meditation"
                )
                
                // XP Reward
                DSFormField(
                    label: "XP Reward",
                    text: $xpReward,
                    placeholder: "10",
                    keyboardType: .numberPad
                )
                
                // Coin Reward
                DSFormField(
                    label: "Coin Reward",
                    text: $coinReward,
                    placeholder: "5",
                    keyboardType: .numberPad
                )
                
                // Cadence
                DSFormField(
                    label: "Cadence (Optional)",
                    text: $cadence,
                    placeholder: "e.g., Daily, Weekly"
                )
                
                // Active toggle
                DSToggleField(
                    label: "Active",
                    isOn: $isActive,
                    helpText: "Active habits will be shown in your habits list"
                )
                
                // Validation errors
                FormValidationView(errors: validationErrors)
            }
        }
        .onAppear {
            if !areas.isEmpty {
                selectedAreaId = areas[0].id
            }
        }
    }
    
    private var isFormValid: Bool {
        !selectedAreaId.isEmpty &&
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (Int(xpReward) ?? 0) > 0 &&
        (Int(coinReward) ?? 0) >= 0
    }
    
    private var validationErrors: [String] {
        var errors: [String] = []
        
        if selectedAreaId.isEmpty {
            errors.append("Please select an area")
        }
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Habit name is required")
        }
        
        if let xp = Int(xpReward), xp <= 0 {
            errors.append("XP reward must be greater than 0")
        } else if Int(xpReward) == nil && !xpReward.isEmpty {
            errors.append("XP reward must be a valid number")
        }
        
        if Int(coinReward) == nil && !coinReward.isEmpty {
            errors.append("Coin reward must be a valid number")
        }
        
        return errors
    }
}
