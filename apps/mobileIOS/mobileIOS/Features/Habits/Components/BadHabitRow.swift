//
//  BadHabitRow.swift
//  mobileIOS
//

import SwiftUI

struct BadHabitRow: View {
    let habit: BadHabit
    @ObservedObject var viewModel: BadHabitsViewModel
    @ObservedObject var streaks: StreaksViewModel
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
                        let count = streaks.perHabit[habit.id]?.currentCount ?? 0
                        StreakBadge(type: .bad, count: count) { showHistory = true }
                        Button(action: { showingEdit = true }) {
                            Image(systemName: "pencil.circle")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                HStack(spacing: 8) {
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
    }
}

