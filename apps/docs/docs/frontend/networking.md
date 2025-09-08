---
title: Networking
---

Networking uses `URLSession` with async/await and a small API client. Requests are typed and errors are surfaced with domain errors.

Client
```swift
struct APIClient {
    var baseURL: URL
    private let session: URLSession = .shared

    func get<T: Decodable>(_ path: String) async throws -> T {
        let url = baseURL.appending(path: path)
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        return try await data(for: req)
    }

    func post<T: Decodable, Body: Encodable>(_ path: String, body: Body?) async throws -> T {
        let url = baseURL.appending(path: path)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        if let body { req.httpBody = try JSONEncoder().encode(body) }
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await data(for: req)
    }

    private func data<T: Decodable>(for request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode, data) }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

enum APIError: Error {
    case invalidResponse
    case httpStatus(Int, Data)
}
```

Endpoints
- Profile: `GET /me`
- User config: `GET /users/:id/config`, `PUT /users/:id/config`
- Habits: `GET /habits`, `POST /actions/habits/:id/complete`
- Bad Habits: `GET /bad-habits`, `POST /actions/bad-habits/:id/record`
- Store: `GET /store/*`, `POST /store/cosmetics/:id/buy` (if applicable)

Tips
- Prefer small request/response DTOs and map to domain models
- Use `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase` if needed
- Log non‑PII failures in debug builds
