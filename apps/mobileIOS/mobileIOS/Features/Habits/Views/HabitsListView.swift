//
//  HabitsListView.swift
//  mobileIOS
//
//  Habits list view component showing good and bad habits
//

import SwiftUI

private final class _LocalStreaksVMLoader: ObservableObject {
    @Published var vm: StreaksViewModel? = nil
}

struct HabitsListView: View {
    @ObservedObject var goodVM: HabitsViewModel
    @ObservedObject var badVM: BadHabitsViewModel
    var onAddGood: () -> Void
    var onAddBad: () -> Void
    
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var app: AppModel
    @StateObject private var streaksVMHolder = _LocalStreaksVMLoader()
    
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
                        
                        DSButton("Complete", icon: "checkmark", style: .primary) {
                            Task {
                                _ = await viewModel.complete(id: habit.id)
                            }
                        }
                    }
                }
                
                HStack(spacing: 8) {
                    if let item = streaks?.perHabit[habit.id] {
                        Label("\(item.currentCount)", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .onTapGesture { showHistory = true }
                    }
                    Spacer()
                    historyDotsGood(history)
                        .onTapGesture { showHistory = true }
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
        .sheet(isPresented: $showHistory) {
            if let streaks {
                HabitHistorySheet(title: habit.name, habitId: habit.id, type: "good", streaks: streaks)
            }
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
                        Label("\(item.currentCount)", systemImage: "shield.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .onTapGesture { showHistory = true }
                    }
                    Spacer()
                    historyDotsBad(history)
                        .onTapGesture { showHistory = true }
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            // Edit sheet would go here
            Text("Edit Bad Habit: \(habit.name)")
        }
        .sheet(isPresented: $showHistory) {
            if let streaks {
                HabitHistorySheet(title: habit.name, habitId: habit.id, type: "bad", streaks: streaks)
            }
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

// MARK: - Habit History Sheet

private struct HabitHistorySheet: View {
    let title: String
    let habitId: String
    let type: String // "good" | "bad"
    @ObservedObject var streaks: StreaksViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var items: [StreaksViewModel.HabitHistoryItem] = []

    private var current: Int { streaks.perHabit[habitId]?.currentCount ?? 0 }
    private var longest: Int { streaks.perHabit[habitId]?.longestCount ?? 0 }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    if type == "good" {
                        Label("\(current)", systemImage: "flame").foregroundStyle(.orange)
                    } else {
                        Label("\(current)", systemImage: "shield").foregroundStyle(.green)
                    }
                    Text("Longest: \(longest)").dsFont(.caption).foregroundStyle(.secondary)
                }

                legend

                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(12), spacing: 6), count: 10), spacing: 6) {
                        ForEach(items.indices, id: \.self) { i in
                            let s = items[i].status
                            if type == "good" {
                                dotGood(status: s)
                            } else {
                                dotBad(status: s)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .navigationTitle(title)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .task {
                await streaks.loadHistoryIfNeeded(habitId: habitId, type: type, days: 30, force: true)
                if type == "good" { items = streaks.goodHistory[habitId] ?? [] } else { items = streaks.badHistory[habitId] ?? [] }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 12) {
            if type == "good" {
                HStack(spacing: 6) { Circle().fill(Color.green).frame(width: 8,height: 8); Text("Done").dsFont(.caption) }
                HStack(spacing: 6) { Circle().stroke(Color.gray, lineWidth: 1).frame(width: 8,height: 8); Text("Miss").dsFont(.caption) }
                HStack(spacing: 6) { Circle().fill(Color.gray.opacity(0.3)).frame(width: 8,height: 8); Text("Inactive").dsFont(.caption) }
            } else {
                HStack(spacing: 6) { Circle().fill(Color.green).frame(width: 8,height: 8); Text("Clean").dsFont(.caption) }
                HStack(spacing: 6) { Circle().fill(Color.yellow).frame(width: 8,height: 8); Text("Forgiven").dsFont(.caption) }
                HStack(spacing: 6) { Circle().fill(Color.red).frame(width: 8,height: 8); Text("Occurred").dsFont(.caption) }
            }
        }
    }
}
