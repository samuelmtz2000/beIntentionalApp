import Foundation

@MainActor
final class HabitsHeaderViewModel: ObservableObject {
    let profileVM: ProfileViewModel
    @Published private(set) var profile: Profile?
    init(profileVM: ProfileViewModel) {
        self.profileVM = profileVM
        self.profile = profileVM.profile
    }
    func refresh() async {
        await profileVM.refresh()
        profile = profileVM.profile
    }
}
