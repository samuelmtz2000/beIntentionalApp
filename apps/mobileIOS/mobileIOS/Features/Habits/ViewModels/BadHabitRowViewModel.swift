import Foundation

@MainActor
final class BadHabitRowViewModel: ObservableObject, Identifiable {
    let id: String
    @Published var habit: BadHabit
    private let badVM: BadHabitsViewModel
    private let streaks: StreaksViewModel

    var onRecord: ((BadHabit) async -> Void)?
    var onEdit: ((BadHabit) -> Void)?
    var onDelete: ((BadHabit) async -> Void)?

    init(habit: BadHabit, badVM: BadHabitsViewModel, streaks: StreaksViewModel,
         onRecord: ((BadHabit) async -> Void)? = nil,
         onEdit: ((BadHabit) -> Void)? = nil,
         onDelete: ((BadHabit) async -> Void)? = nil) {
        self.id = habit.id
        self.habit = habit
        self.badVM = badVM
        self.streaks = streaks
        self.onRecord = onRecord
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    func record() async {
        if let onRecord { await onRecord(habit) } else { _ = await badVM.record(id: habit.id, payWithCoins: false) }
        await streaks.refreshPerHabit(days: 7)
    }

    func edit() { if let onEdit { onEdit(habit) } }

    func delete() async {
        if let onDelete { await onDelete(habit) } else { await badVM.delete(id: habit.id) }
        await streaks.refreshPerHabit(days: 7)
    }

    var penaltyText: String { "-\(habit.lifePenalty)" }
    func currentStreakCount() -> Int { streaks.perHabit[habit.id]?.currentCount ?? 0 }
}

