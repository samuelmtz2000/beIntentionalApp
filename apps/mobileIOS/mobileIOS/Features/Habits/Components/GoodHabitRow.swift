//
//  GoodHabitRow.swift
//  mobileIOS
//

import SwiftUI

struct GoodHabitRow: View {
    let habit: GoodHabit
    @ObservedObject var viewModel: HabitsViewModel
    @ObservedObject var streaks: StreaksViewModel
    var onComplete: ((GoodHabit) async -> Void)? = nil
    var onEdit: ((GoodHabit) -> Void)? = nil
    var onDelete: ((GoodHabit) async -> Void)? = nil
    @State private var showingEdit = false
    @State private var history: [StreaksViewModel.HabitHistoryItem] = []
    @State private var showHistory = false

    var body: some View {
        DSCard {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(habit.name)
                            .dsFont(.body)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        if let cadence = habit.cadence, !cadence.isEmpty {
                            Text(cadence)
                                .dsFont(.body) // same font and size, subtle color
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    HStack(spacing: 8) {
                        let count = streaks.perHabit[habit.id]?.currentCount ?? 0
                        StreakChip(kind: .good, count: count) { showHistory = true }
                        GoodHistoryDotsView(history: history)
                            .onTapGesture { showHistory = true }
                    }

                    // cadence moved next to name
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Label("+\(habit.xpReward)", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Label("+\(habit.coinReward)", systemImage: "creditcard")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
        }
        // Inline edit removed; invoke via swipe (onEdit)
        .sheet(isPresented: $showHistory) { HabitHistorySheet(title: habit.name, habitId: habit.id, type: "good", streaks: streaks) }
        .task {
            await streaks.loadHistoryIfNeeded(habitId: habit.id, type: "good", days: 7)
            history = streaks.goodHistory[habit.id] ?? []
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                Task {
                    if let onComplete { await onComplete(habit) } else { _ = await viewModel.complete(id: habit.id) }
                    await streaks.refreshPerHabit(days: 7)
                }
            } label: { Label("Record", systemImage: "checkmark.circle.fill") }.tint(.green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                if let onEdit { onEdit(habit) } else { showingEdit = true }
            } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
            Button(role: .destructive) {
                Task {
                    if let onDelete { await onDelete(habit) } else { await viewModel.delete(id: habit.id) }
                    await streaks.refreshPerHabit(days: 7)
                }
            } label: { Label("Delete", systemImage: "trash") }
        }
    }
}
