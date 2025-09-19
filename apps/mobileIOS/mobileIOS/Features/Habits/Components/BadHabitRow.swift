//
//  BadHabitRow.swift
//  mobileIOS
//

import SwiftUI

struct BadHabitRow: View {
    let habit: BadHabit
    @ObservedObject var viewModel: BadHabitsViewModel
    @ObservedObject var streaks: StreaksViewModel
    var onRecord: ((BadHabit) async -> Void)? = nil
    var onEdit: ((BadHabit) -> Void)? = nil
    var onDelete: ((BadHabit) async -> Void)? = nil
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
                            Label("-\(habit.lifePenalty) Life", systemImage: "heart.slash")
                                .font(.caption)
                                .foregroundStyle(.red)
                            if habit.controllable {
                                Label("\(habit.coinCost) Coins", systemImage: "creditcard")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
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
                    StreakChip(kind: .bad, count: count) { showHistory = true }
                    BadHistoryDotsView(history: history)
                        .onTapGesture { showHistory = true }
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showingEdit) { Text("Edit Bad Habit: \(habit.name)") }
        .sheet(isPresented: $showHistory) { HabitHistorySheet(title: habit.name, habitId: habit.id, type: "bad", streaks: streaks) }
        .task {
            await streaks.loadHistoryIfNeeded(habitId: habit.id, type: "bad", days: 7)
            history = streaks.badHistory[habit.id] ?? []
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                Task {
                    if let onRecord { await onRecord(habit) } else { await viewModel.record(id: habit.id, payWithCoins: false) }
                    await streaks.refreshPerHabit(days: 7)
                }
            } label: { Label("Record", systemImage: "exclamationmark.circle") }.tint(.red)
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
