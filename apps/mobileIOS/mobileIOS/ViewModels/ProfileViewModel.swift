import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: Profile?
    @Published var isLoading = false
    @Published var error: APIError?

    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do { profile = try await api.get("me") }
        catch let e as APIError { error = e }
        catch { error = APIError(message: error.localizedDescription) }
    }
}

