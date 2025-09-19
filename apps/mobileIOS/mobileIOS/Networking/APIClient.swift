import Foundation

struct APIError: Error, LocalizedError, Identifiable {
    let id = UUID()
    let message: String
    let status: Int?
    var errorDescription: String? { message }
    init(message: String, status: Int? = nil) {
        self.message = message
        self.status = status
    }
}

final class APIClient {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func get<T: Decodable>(_ path: String) async throws -> T {
        let url = try buildURL(path)
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        return try await perform(req)
    }

    func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let url = try buildURL(path)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        return try await perform(req)
    }

    func put<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let url = try buildURL(path)
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        return try await perform(req)
    }

    func delete(_ path: String) async throws {
        let url = try buildURL(path)
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        _ = try await performRaw(req) as Data
    }

    private func buildURL(_ path: String) throws -> URL {
        // Support paths with query strings by building URLComponents
        guard var comps = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw APIError(message: "Invalid base URL")
        }
        var basePath = comps.path
        if !basePath.hasSuffix("/") { basePath += "/" }
        let parts = path.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        comps.path = basePath + (parts.first ?? "")
        if parts.count > 1 { comps.percentEncodedQuery = parts[1] }
        guard let url = comps.url else { throw APIError(message: "Invalid URL for path: \(path)") }
        return url
    }

    private func perform<T: Decodable>(_ req: URLRequest) async throws -> T {
        let data = try await performRaw(req)
        do { return try JSONDecoder.api.decode(T.self, from: data) }
        catch { throw APIError(message: String(data: data, encoding: .utf8) ?? error.localizedDescription) }
    }

    private func performRaw(_ req: URLRequest) async throws -> Data {
        do {
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse else { throw APIError(message: "Invalid response") }
            guard 200..<300 ~= http.statusCode else {
                let body = String(data: data, encoding: .utf8)
                let msg = body?.isEmpty == false ? body! : "HTTP \(http.statusCode)"
                throw APIError(message: msg, status: http.statusCode)
            }
            return data
        } catch {
            if let e = error as? APIError { throw e }
            throw APIError(message: error.localizedDescription)
        }
    }
}

extension JSONDecoder {
    static let api: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
