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

    @State private var prev: Int = 0
    @State private var bounce: Bool = false

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
        .scaleEffect(bounce ? 1.12 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: bounce)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .accessibilityLabel(kind == .good ? "Good habit streak \(count)" : "Clean streak \(count)")
        .onAppear { prev = count }
        .onChange(of: count) { old, newVal in
            let increased = newVal > prev
            prev = newVal
            if increased { bounce = true; DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { bounce = false } }
        }
    }
}
