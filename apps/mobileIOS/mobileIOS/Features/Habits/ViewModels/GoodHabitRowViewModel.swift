import Foundation

@MainActor
final class GoodHabitRowViewModel: ObservableObject, Identifiable {
    let id: String
    @Published var habit: GoodHabit
    private let goodVM: HabitsViewModel
    private let streaks: StreaksViewModel

    // Optional action overrides
    var onComplete: ((GoodHabit) async -> Void)?
    var onEdit: ((GoodHabit) -> Void)?
    var onDelete: ((GoodHabit) async -> Void)?

    init(habit: GoodHabit, goodVM: HabitsViewModel, streaks: StreaksViewModel,
         onComplete: ((GoodHabit) async -> Void)? = nil,
         onEdit: ((GoodHabit) -> Void)? = nil,
         onDelete: ((GoodHabit) async -> Void)? = nil) {
        self.id = habit.id
        self.habit = habit
        self.goodVM = goodVM
        self.streaks = streaks
        self.onComplete = onComplete
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    func complete() async {
        if let onComplete { await onComplete(habit) } else { _ = await goodVM.complete(id: habit.id) }
        await streaks.refreshPerHabit(days: 7)
        NotificationCenter.default.post(name: .streaksDidChange, object: nil)
    }

    func edit() { if let onEdit { onEdit(habit) } }

    func delete() async {
        if let onDelete { await onDelete(habit) } else { await goodVM.delete(id: habit.id) }
        await streaks.refreshPerHabit(days: 7)
    }

    var cadenceText: String? { habit.cadence }
    var xpText: String { "+\(habit.xpReward)" }
    var coinText: String { "+\(habit.coinReward)" }
    func currentStreakCount() -> Int { streaks.perHabit[habit.id]?.currentCount ?? 0 }
}
