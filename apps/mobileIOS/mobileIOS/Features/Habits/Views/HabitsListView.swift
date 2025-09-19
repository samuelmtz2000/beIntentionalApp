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
        List {
            Section {
                if goodVM.habits.isEmpty {
                    DSEmptyState(
                        icon: "plus.circle",
                        title: "No Good Habits",
                        message: "Start building positive habits to earn XP and coins",
                        actionTitle: "Add Habit",
                        action: onAddGood
                    )
                    .listRowBackground(Color.clear)
                } else {
                    if let vm = streaksVMHolder.vm {
                        ForEach(goodVM.habits) { habit in
                            let rowVM = GoodHabitRowViewModel(
                                habit: habit,
                                goodVM: goodVM,
                                streaks: vm,
                                onComplete: onGoodComplete,
                                onEdit: onGoodEdit,
                                onDelete: onGoodDelete
                            )
                            GoodHabitRow(vm: rowVM, streaks: vm)
                                .listRowBackground(Color.clear)
                        }
                    } else {
                        let temp = StreaksViewModel(api: app.api)
                        ForEach(goodVM.habits) { habit in
                            let rowVM = GoodHabitRowViewModel(habit: habit, goodVM: goodVM, streaks: temp)
                            GoodHabitRow(vm: rowVM, streaks: temp)
                                .listRowBackground(Color.clear)
                        }
                    }
                }
            } header: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                    Text("Good Habits").dsFont(.headerMD).bold()
                    Spacer()
                    Button(action: onAddGood) {
                        Image(systemName: "plus.circle.fill").foregroundStyle(.blue)
                    }
                    .accessibilityLabel(Text("Add Good Habit"))
                }
            }

            Section {
                if badVM.items.isEmpty {
                    DSEmptyState(
                        icon: "shield.slash",
                        title: "No Bad Habits",
                        message: "Track negative habits to maintain accountability",
                        actionTitle: "Add Bad Habit",
                        action: onAddBad
                    )
                    .listRowBackground(Color.clear)
                } else {
                    if let vm = streaksVMHolder.vm {
                        ForEach(badVM.items) { habit in
                            let rowVM = BadHabitRowViewModel(
                                habit: habit,
                                badVM: badVM,
                                streaks: vm,
                                onRecord: onBadRecord,
                                onEdit: onBadEdit,
                                onDelete: onBadDelete
                            )
                            BadHabitRow(vm: rowVM, streaks: vm)
                                .listRowBackground(Color.clear)
                        }
                    } else {
                        let temp = StreaksViewModel(api: app.api)
                        ForEach(badVM.items) { habit in
                            let rowVM = BadHabitRowViewModel(habit: habit, badVM: badVM, streaks: temp)
                            BadHabitRow(vm: rowVM, streaks: temp)
                                .listRowBackground(Color.clear)
                        }
                    }
                }
            } header: {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text("Bad Habits").dsFont(.headerMD).bold()
                    Spacer()
                    Button(action: onAddBad) {
                        Image(systemName: "plus.circle.fill").foregroundStyle(.red)
                    }
                    .accessibilityLabel(Text("Add Bad Habit"))
                }
            }
        }
        .listStyle(.plain)
        .task {
            if streaksVMHolder.vm == nil { streaksVMHolder.vm = StreaksViewModel(api: app.api) }
            if let vm = streaksVMHolder.vm {
                await vm.refreshPerHabit(days: 7)
            }
        }
    }
}

// Components moved to Features/Habits/Components/*
