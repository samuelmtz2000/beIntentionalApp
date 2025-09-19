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
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(habit.name)
                            .dsFont(.body)
                            .foregroundStyle(.primary)

                        HStack(spacing: 12) {
                            Label("+\(habit.xpReward) XP", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Label("+\(habit.coinReward) Coins", systemImage: "creditcard")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Button(action: { showingEdit = true }) {
                            Image(systemName: "pencil.circle")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                HStack(spacing: 10) {
                    let count = streaks.perHabit[habit.id]?.currentCount ?? 0
                    StreakChip(kind: .good, count: count) { showHistory = true }
                    GoodHistoryDotsView(history: history)
                        .onTapGesture { showHistory = true }
                    Spacer()
                }

                if let cadence = habit.cadence, !cadence.isEmpty {
                    Text("Cadence: \(cadence)")
                        .dsFont(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingEdit) { Text("Edit Habit: \(habit.name)") }
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
