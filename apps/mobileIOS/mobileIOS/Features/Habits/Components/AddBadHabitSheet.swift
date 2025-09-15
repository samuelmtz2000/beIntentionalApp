//
//  AddBadHabitSheet.swift
//  mobileIOS
//
//  Sheet for adding a new bad habit using consistent form patterns
//

import SwiftUI

struct AddBadHabitSheet: View {
    let areas: [Area]
    let onSave: (String?, String, Int, Bool, Int, Bool) async -> Void
    
    @State private var selectedAreaId = ""
    @State private var name = ""
    @State private var lifePenalty = "5"
    @State private var controllable = false
    @State private var coinCost = "0"
    @State private var isActive = true
    @State private var isGlobalHabit = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        DSSheet(
            title: "New Bad Habit",
            onCancel: { dismiss() },
            onSave: {
                await onSave(
                    isGlobalHabit ? nil : selectedAreaId,
                    name,
                    Int(lifePenalty) ?? 5,
                    controllable,
                    Int(coinCost) ?? 0,
                    isActive
                )
                dismiss()
            },
            canSave: isFormValid
        ) {
            VStack(spacing: 16) {
                // Global habit toggle
                DSToggleField(
                    label: "Global Habit",
                    isOn: $isGlobalHabit,
                    helpText: "Global habits are not tied to a specific area"
                )
                
                // Area selection (if not global)
                if !isGlobalHabit {
                    DSPickerField(
                        label: "Area",
                        selection: $selectedAreaId,
                        options: areas.map { $0.id },
                        displayName: { id in
                            areas.first { $0.id == id }?.name ?? "Unknown"
                        }
                    )
                }
                
                // Habit name
                DSFormField(
                    label: "Habit Name",
                    text: $name,
                    placeholder: "e.g., Eating junk food"
                )
                
                // Life Penalty
                DSFormField(
                    label: "Life Penalty",
                    text: $lifePenalty,
                    placeholder: "5",
                    keyboardType: .numberPad
                )
                
                // Controllable toggle
                DSToggleField(
                    label: "Controllable",
                    isOn: $controllable,
                    helpText: "Controllable habits can be paid for with coins to avoid life penalty"
                )
                
                // Coin Cost (if controllable)
                if controllable {
                    DSFormField(
                        label: "Coin Cost",
                        text: $coinCost,
                        placeholder: "10",
                        keyboardType: .numberPad
                    )
                }
                
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
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (Int(lifePenalty) ?? 0) > 0 &&
        (!controllable || (Int(coinCost) ?? 0) > 0) &&
        (isGlobalHabit || !selectedAreaId.isEmpty)
    }
    
    private var validationErrors: [String] {
        var errors: [String] = []
        
        if !isGlobalHabit && selectedAreaId.isEmpty {
            errors.append("Please select an area or mark as global")
        }
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Habit name is required")
        }
        
        if let penalty = Int(lifePenalty), penalty <= 0 {
            errors.append("Life penalty must be greater than 0")
        } else if Int(lifePenalty) == nil && !lifePenalty.isEmpty {
            errors.append("Life penalty must be a valid number")
        }
        
        if controllable {
            if let cost = Int(coinCost), cost <= 0 {
                errors.append("Coin cost must be greater than 0 for controllable habits")
            } else if Int(coinCost) == nil && !coinCost.isEmpty {
                errors.append("Coin cost must be a valid number")
            }
        }
        
        return errors
    }
}
