//
//  GoodHabitRow.swift
//  mobileIOS
//

import SwiftUI

struct GoodHabitRow: View {
    let habit: GoodHabit
    @ObservedObject var viewModel: HabitsViewModel
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
                        let count = streaks.perHabit[habit.id]?.currentCount ?? 0
                        StreakBadge(type: .good, count: count) { showHistory = true }
                        Button(action: { showingEdit = true }) {
                            Image(systemName: "pencil.circle")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                HStack(spacing: 8) {
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
    }
}

