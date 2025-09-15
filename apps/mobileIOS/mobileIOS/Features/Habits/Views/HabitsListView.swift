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
                            GoodHabitRow(habit: habit, viewModel: goodVM)
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
                            BadHabitRow(habit: habit, viewModel: badVM)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Good Habit Row

struct GoodHabitRow: View {
    let habit: GoodHabit
    @ObservedObject var viewModel: HabitsViewModel
    @State private var showingEdit = false
    
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
    }
}

// MARK: - Bad Habit Row

struct BadHabitRow: View {
    let habit: BadHabit
    @ObservedObject var viewModel: BadHabitsViewModel
    @State private var showingEdit = false
    
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
            }
        }
        .sheet(isPresented: $showingEdit) {
            // Edit sheet would go here
            Text("Edit Bad Habit: \(habit.name)")
        }
    }
}
