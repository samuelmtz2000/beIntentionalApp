import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: Profile?
    @Published var isLoading = false
    @Published var apiError: APIError?

    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do { profile = try await api.get("me") }
        catch let e as APIError { apiError = e }
        catch { apiError = APIError(message: error.localizedDescription) }
    }
}
