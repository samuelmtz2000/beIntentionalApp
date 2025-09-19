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
    // Action overrides (optional); defaults call VMs directly
    var onGoodComplete: ((GoodHabit) async -> Void)? = nil
    var onGoodEdit: ((GoodHabit) -> Void)? = nil
    var onGoodDelete: ((GoodHabit) async -> Void)? = nil
    var onBadRecord: ((BadHabit) async -> Void)? = nil
    var onBadEdit: ((BadHabit) -> Void)? = nil
    var onBadDelete: ((BadHabit) async -> Void)? = nil
    
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
                        if let vm = streaksVMHolder.vm {
                            ForEach(goodVM.habits) { habit in
                                GoodHabitRow(
                                    habit: habit,
                                    viewModel: goodVM,
                                    streaks: vm,
                                    onComplete: onGoodComplete ?? { h in _ = await goodVM.complete(id: h.id) },
                                    onEdit: onGoodEdit ?? { _ in },
                                    onDelete: onGoodDelete ?? { h in await goodVM.delete(id: h.id) }
                                )
                            }
                        } else {
                            // Fallback: render rows with a temporary VM to show 0-count badges
                            let temp = StreaksViewModel(api: app.api)
                            ForEach(goodVM.habits) { habit in
                                GoodHabitRow(habit: habit, viewModel: goodVM, streaks: temp)
                            }
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
                    if let vm = streaksVMHolder.vm {
                        ForEach(badVM.items) { habit in
                            BadHabitRow(
                                habit: habit,
                                viewModel: badVM,
                                streaks: vm,
                                onRecord: onBadRecord ?? { b in await badVM.record(id: b.id, payWithCoins: false) },
                                onEdit: onBadEdit ?? { _ in },
                                onDelete: onBadDelete ?? { b in await badVM.delete(id: b.id) }
                            )
                        }
                    } else {
                        let temp = StreaksViewModel(api: app.api)
                        ForEach(badVM.items) { habit in
                            BadHabitRow(habit: habit, viewModel: badVM, streaks: temp)
                        }
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

// Components moved to Features/Habits/Components/*
