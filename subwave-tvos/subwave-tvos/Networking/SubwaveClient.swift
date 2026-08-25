//
//  SubwaveClient.swift
//  subwave-tvos
//

import Foundation

enum SubwaveError: Error {
    case invalidStationAddress
    case invalidResponse
    case requestNotFound
    case http(status: Int)
}

/// Talks to one SUB/WAVE station's HTTP API. Credentials (when the station
/// address carried `user:pass@`) are sent as an explicit `Authorization:
/// Basic` header on every request rather than left in the URL — the same
/// approach the stream player has to use anyway (AVPlayer drops userinfo from
/// media URLs, per docs/private-station.md), so one code path covers both.
struct SubwaveClient {
    let baseURL: URL
    let credentials: StationCredentials?

    init?(station: Station) {
        guard let resolved = station.resolvedAddress else { return nil }
        self.baseURL = resolved.baseURL
        self.credentials = resolved.credentials
    }

    func fetchNowPlaying() async throws -> NowPlayingResponse {
        try await get("/now-playing")
    }

    func fetchDJ() async throws -> DJPersona {
        try await get("/dj")
    }

    /// Fetches cover art directly (rather than handing `AsyncImage` a bare
    /// URL) because a station behind its own basic-auth lock needs the same
    /// `Authorization` header every other request here gets.
    func fetchCoverImageData(id: String) async throws -> Data {
        let url = baseURL.appendingPathComponent("/cover/\(id)")
        let request = authorizedRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)
        return data
    }

    func submitRequest(text: String, name: String?) async throws -> RequestReceipt {
        try await post("/request", body: RequestSubmission(text: text, name: name))
    }

    func fetchRequestOutcome(id: String) async throws -> RequestOutcome {
        do {
            return try await get("/request/\(id)")
        } catch SubwaveError.http(let status) where status == 404 {
            return RequestOutcome(status: "unknown")
        }
    }

    // MARK: - Plumbing

    private func authorizedRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        if let credentials {
            let raw = "\(credentials.username):\(credentials.password)"
            if let token = raw.data(using: .utf8)?.base64EncodedString() {
                request.setValue("Basic \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        return request
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        let request = authorizedRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func post<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = authorizedRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw SubwaveError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            throw SubwaveError.http(status: http.statusCode)
        }
    }
}
