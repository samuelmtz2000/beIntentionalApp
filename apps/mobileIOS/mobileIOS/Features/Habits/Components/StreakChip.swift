//
//  StreakChip.swift
//  mobileIOS
//

import SwiftUI

struct StreakChip: View {
    enum Kind { case good, bad }
    let kind: Kind
    let count: Int
    var onTap: (() -> Void)? = nil

    private var icon: String { kind == .good ? "flame" : "shield" }
    private var tint: Color { kind == .good ? .orange : .green }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .symbolRenderingMode(.monochrome)
                .foregroundColor(tint)
                .font(.callout)
            Text("\(count)")
                .font(.caption)
                .foregroundColor(tint)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(tint.opacity(0.18))
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .accessibilityLabel(kind == .good ? "Good habit streak \(count)" : "Clean streak \(count)")
    }
}

