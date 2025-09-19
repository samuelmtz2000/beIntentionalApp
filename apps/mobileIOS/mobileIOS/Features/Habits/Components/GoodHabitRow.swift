//
//  GoodHabitRow.swift
//  mobileIOS
//

import SwiftUI

struct GoodHabitRow: View {
    @ObservedObject var vm: GoodHabitRowViewModel
    @ObservedObject var streaks: StreaksViewModel
    @State private var showingEdit = false
    @State private var history: [StreaksViewModel.HabitHistoryItem] = []
    @State private var showHistory = false

    var body: some View {
        DSCard {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(vm.habit.name)
                            .dsFont(.body)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        if let cadence = vm.cadenceText, !cadence.isEmpty {
                            Text(cadence)
                                .dsFont(.caption) // smaller than name
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    HStack(spacing: 8) {
                        StreakChip(kind: .good, count: vm.currentStreakCount()) { showHistory = true }
                        GoodHistoryDotsView(history: history)
                            .onTapGesture { showHistory = true }
                    }

                    // cadence moved next to name
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Label(vm.xpText, systemImage: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Label(vm.coinText, systemImage: "creditcard")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
        }
        // Inline edit removed; invoke via swipe (onEdit)
        .sheet(isPresented: $showHistory) { HabitHistorySheet(title: vm.habit.name, habitId: vm.habit.id, type: "good", streaks: streaks) }
        .task {
            await streaks.loadHistoryIfNeeded(habitId: vm.habit.id, type: "good", days: 7)
            history = streaks.goodHistory[vm.habit.id] ?? []
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                Task {
                    await vm.complete()
                }
            } label: { Label("Record", systemImage: "checkmark.circle.fill") }.tint(.green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                vm.edit()
            } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
            Button(role: .destructive) {
                Task {
                    await vm.delete()
                }
            } label: { Label("Delete", systemImage: "trash") }
        }
    }
}
