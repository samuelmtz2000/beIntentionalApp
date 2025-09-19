import Foundation

@MainActor
final class HabitsHeaderViewModel: ObservableObject {
    @ObservedObject var profileVM: ProfileViewModel
    init(profileVM: ProfileViewModel) { self.profileVM = profileVM }
    var profile: Profile? { profileVM.profile }
    func refresh() async { await profileVM.refresh() }
}

