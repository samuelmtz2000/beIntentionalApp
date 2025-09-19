//
//  BadHabitRow.swift
//  mobileIOS
//

import SwiftUI

struct BadHabitRow: View {
    @ObservedObject var vm: BadHabitRowViewModel
    @ObservedObject var streaks: StreaksViewModel
    @State private var showingEdit = false
    @State private var history: [StreaksViewModel.HabitHistoryItem] = []
    @State private var showHistory = false

    var body: some View {
        DSCard {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(vm.habit.name)
                        .dsFont(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        StreakChip(kind: .bad, count: vm.currentStreakCount()) { showHistory = true }
                        BadHistoryDotsView(history: history)
                            .onTapGesture { showHistory = true }
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Label(vm.penaltyText, systemImage: "heart.slash")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        // Inline edit removed; invoke via swipe (onEdit)
        .sheet(isPresented: $showHistory) { HabitHistorySheet(title: vm.habit.name, habitId: vm.habit.id, type: "bad", streaks: streaks) }
        .task {
            await streaks.loadHistoryIfNeeded(habitId: vm.habit.id, type: "bad", days: 7)
            history = streaks.badHistory[vm.habit.id] ?? []
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                Task {
                    await vm.record()
                }
            } label: { Label("Record", systemImage: "exclamationmark.circle") }.tint(.red)
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
