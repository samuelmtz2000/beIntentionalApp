//
//  AddAreaSheet.swift
//  mobileIOS
//
//  Sheet for adding a new area using consistent form patterns
//

import SwiftUI

struct AddAreaSheet: View {
    let onSave: (String, String?, Int, String, Double) async -> Void
    
    @State private var name = ""
    @State private var icon = ""
    @State private var xpPerLevel = "100"
    @State private var levelCurve = "linear"
    @State private var levelMultiplier = "1.5"
    
    @Environment(\.dismiss) private var dismiss
    
    let curveOptions = ["linear", "exp"]
    
    var body: some View {
        DSSheet(
            title: "New Area",
            onCancel: { dismiss() },
            onSave: {
                await onSave(
                    name,
                    icon.isEmpty ? nil : icon,
                    Int(xpPerLevel) ?? 100,
                    levelCurve,
                    Double(levelMultiplier) ?? 1.5
                )
                dismiss()
            },
            canSave: isFormValid
        ) {
            VStack(spacing: 16) {
                // Area name
                DSFormField(
                    label: "Area Name",
                    text: $name,
                    placeholder: "e.g., Health, Learning, Finance"
                )
                
                // Icon (optional)
                DSFormField(
                    label: "Icon (Optional)",
                    text: $icon,
                    placeholder: "e.g., heart.fill, book.fill"
                )
                
                // XP per level
                DSFormField(
                    label: "XP Per Level",
                    text: $xpPerLevel,
                    placeholder: "100",
                    keyboardType: .numberPad
                )
                
                // Level curve
                DSPickerField(
                    label: "Level Curve",
                    selection: $levelCurve,
                    options: curveOptions,
                    displayName: { curve in
                        curve == "linear" ? "Linear" : "Exponential"
                    }
                )
                
                // Level multiplier (for exponential curve)
                if levelCurve == "exp" {
                    DSFormField(
                        label: "Level Multiplier",
                        text: $levelMultiplier,
                        placeholder: "1.5",
                        keyboardType: .decimalPad
                    )
                    
                    Text("Each level will require \(levelMultiplier)x more XP than the previous")
                        .dsFont(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview")
                        .dsFont(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Text("Level 1:")
                        Spacer()
                        Text("\(Int(xpPerLevel) ?? 100) XP")
                    }
                    .dsFont(.caption)
                    
                    HStack {
                        Text("Level 2:")
                        Spacer()
                        Text("\(calculateXPForLevel(2)) XP")
                    }
                    .dsFont(.caption)
                    
                    HStack {
                        Text("Level 3:")
                        Spacer()
                        Text("\(calculateXPForLevel(3)) XP")
                    }
                    .dsFont(.caption)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                )
                
                // Validation errors
                FormValidationView(errors: validationErrors)
            }
        }
    }
    
    private func calculateXPForLevel(_ level: Int) -> Int {
        let base = Int(xpPerLevel) ?? 100
        if levelCurve == "exp" {
            let mult = Double(levelMultiplier) ?? 1.5
            let power = pow(mult, Double(level - 1))
            return Int(Double(base) * power)
        } else {
            return base
        }
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (Int(xpPerLevel) ?? 0) >= 10 &&
        (levelCurve != "exp" || (Double(levelMultiplier) ?? 0) > 1.0)
    }
    
    private var validationErrors: [String] {
        var errors: [String] = []
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Area name is required")
        }
        
        if let xp = Int(xpPerLevel), xp < 10 {
            errors.append("XP per level must be at least 10")
        } else if Int(xpPerLevel) == nil && !xpPerLevel.isEmpty {
            errors.append("XP per level must be a valid number")
        }
        
        if levelCurve == "exp" {
            if let mult = Double(levelMultiplier), mult <= 1.0 {
                errors.append("Level multiplier must be greater than 1.0 for exponential curve")
            } else if Double(levelMultiplier) == nil && !levelMultiplier.isEmpty {
                errors.append("Level multiplier must be a valid decimal number")
            }
        }
        
        return errors
    }
}
