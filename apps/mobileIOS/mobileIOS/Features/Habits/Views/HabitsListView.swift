//
//  HabitsListView.swift
//  mobileIOS
//
//  Habits list view component showing good and bad habits
//

import SwiftUI

struct HabitsListView: View {
    @ObservedObject var goodVM: HabitsViewModel
    @ObservedObject var badVM: BadHabitsViewModel
    var onAddGood: () -> Void
    var onAddBad: () -> Void
    
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var app: AppModel
    @StateObject private var streaksVMHolder = _StreaksVMLoader()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Good Habits Section
                VStack(alignment: .leading, spacing: 12) {
                    DSSectionHeader(
                        title: "Good Habits",
                        icon: "checkmark.seal.fill",
                        iconColor: .green
                    )
                    
                    if goodVM.habits.isEmpty {
                        DSEmptyState(
                            icon: "plus.circle",
                            title: "No Good Habits",
                            message: "Start building positive habits to earn XP and coins",
                            actionTitle: "Add Habit",
                            action: onAddGood
                        )
                    } else {
                        ForEach(goodVM.habits) { habit in
                            GoodHabitRow(habit: habit, viewModel: goodVM, streaks: streaksVMHolder.vm)
                        }
                    }
                }
                
                Divider()
                    .padding(.horizontal)
                
                // Bad Habits Section
                VStack(alignment: .leading, spacing: 12) {
                    DSSectionHeader(
                        title: "Bad Habits",
                        icon: "exclamationmark.triangle.fill",
                        iconColor: .orange
                    )
                    
                if badVM.items.isEmpty {
                        DSEmptyState(
                            icon: "shield.slash",
                            title: "No Bad Habits",
                            message: "Track negative habits to maintain accountability",
                            actionTitle: "Add Bad Habit",
                            action: onAddBad
                        )
                } else {
                    ForEach(badVM.items) { habit in
                            BadHabitRow(habit: habit, viewModel: badVM, streaks: streaksVMHolder.vm)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .task {
            if streaksVMHolder.vm == nil { streaksVMHolder.vm = StreaksViewModel(api: app.api) }
            if let vm = streaksVMHolder.vm {
                await vm.refreshPerHabit(days: 7)
            }
        }
    }
}

// MARK: - Good Habit Row

struct GoodHabitRow: View {
    let habit: GoodHabit
    @ObservedObject var viewModel: HabitsViewModel
    @State private var showingEdit = false
    var streaks: StreaksViewModel?
    @State private var history: [StreaksViewModel.HabitHistoryItem] = []
    
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
                        
                        DSButton("Complete", icon: "checkmark", style: .primary) {
                            Task {
                                _ = await viewModel.complete(id: habit.id)
                            }
                        }
                    }
                }
                
                HStack(spacing: 8) {
                    if let item = streaks?.perHabit[habit.id] {
                        Label("\(item.currentCount)", systemImage: "flame")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Spacer()
                    historyDotsGood(history)
                }

                if let cadence = habit.cadence, !cadence.isEmpty {
                    Text("Cadence: \(cadence)")
                        .dsFont(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            // Edit sheet would go here
            Text("Edit Habit: \(habit.name)")
        }
        .task {
            guard let streaks else { return }
            await streaks.loadHistoryIfNeeded(habitId: habit.id, type: "good", days: 7)
            if let h = streaks.goodHistory[habit.id] { history = h }
        }
    }
}

// MARK: - Bad Habit Row

struct BadHabitRow: View {
    let habit: BadHabit
    @ObservedObject var viewModel: BadHabitsViewModel
    @State private var showingEdit = false
    var streaks: StreaksViewModel?
    @State private var history: [StreaksViewModel.HabitHistoryItem] = []
    
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
                        
                        if habit.controllable {
                            DSButton("Pay \(habit.coinCost)", icon: "creditcard", style: .secondary) {
                                Task {
                                    await viewModel.record(id: habit.id, payWithCoins: true)
                                }
                            }
                        }
                        
                        DSButton("I Slipped", style: .destructive) {
                            Task {
                                await viewModel.record(id: habit.id, payWithCoins: false)
                            }
                        }
                    }
                }
                HStack(spacing: 8) {
                    if let item = streaks?.perHabit[habit.id] {
                        Label("\(item.currentCount)", systemImage: "shield")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    Spacer()
                    historyDotsBad(history)
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            // Edit sheet would go here
            Text("Edit Bad Habit: \(habit.name)")
        }
        .task {
            guard let streaks else { return }
            await streaks.loadHistoryIfNeeded(habitId: habit.id, type: "bad", days: 7)
            if let h = streaks.badHistory[habit.id] { history = h }
        }
    }
}

// MARK: - Mini Calendar Dots

private func historyDotsGood(_ hist: [StreaksViewModel.HabitHistoryItem]) -> some View {
    HStack(spacing: 4) {
        ForEach(Array(hist.suffix(7)).indices, id: \.self) { i in
            let item = Array(hist.suffix(7))[i]
            dotGood(status: item.status)
        }
    }
}

private func dotGood(status: String) -> some View {
    Group {
        if status == "done" {
            Circle().fill(Color.green).frame(width: 8, height: 8)
        } else if status == "inactive" {
            Circle().fill(Color.gray.opacity(0.3)).frame(width: 8, height: 8)
        } else {
            Circle().stroke(Color.gray, lineWidth: 1).frame(width: 8, height: 8)
        }
    }
}

private func historyDotsBad(_ hist: [StreaksViewModel.HabitHistoryItem]) -> some View {
    HStack(spacing: 4) {
        ForEach(Array(hist.suffix(7)).indices, id: \.self) { i in
            let item = Array(hist.suffix(7))[i]
            dotBad(status: item.status)
        }
    }
}

private func dotBad(status: String) -> some View {
    Group {
        if status == "occurred" {
            Circle().fill(Color.red).frame(width: 8, height: 8)
        } else if status == "forgiven" {
            Circle().fill(Color.yellow).frame(width: 8, height: 8)
        } else {
            Circle().fill(Color.green).frame(width: 8, height: 8)
        }
    }
}
