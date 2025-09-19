//
//  StreakBadge.swift
//  mobileIOS
//

import SwiftUI

enum StreakType { case good, bad }

struct StreakBadge: View {
    let type: StreakType
    let count: Int
    var onTap: (() -> Void)? = nil

    var body: some View {
        let (icon, color): (String, Color) = {
            switch type {
            case .good: return ("flame.fill", .orange)
            case .bad: return ("shield.fill", .green)
            }
        }()
        Label("\(count)", systemImage: icon)
            .font(.caption)
            .foregroundStyle(color)
            .imageScale(.medium)
            .contentShape(Rectangle())
            .onTapGesture { onTap?() }
            .accessibilityLabel(type == .good ? "Good habit streak \(count)" : "Clean streak \(count)")
    }
}

