import Foundation

public enum HTTPClientError: LocalizedError {
    case invalidResponse
    case requestFailed(status: Int, body: String)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The TRMNL webhook returned a non-HTTP response."
        case let .requestFailed(status, body):
            return "The TRMNL webhook returned HTTP \(status): \(body)"
        }
    }
}

public struct HTTPClient: Sendable {
    public init() {}

    public func postJSON(_ data: Data, to url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw HTTPClientError.invalidResponse
        }

        let body = String(data: responseData, encoding: .utf8) ?? ""
        guard (200..<300).contains(http.statusCode) else {
            throw HTTPClientError.requestFailed(status: http.statusCode, body: body)
        }

        return body
    }
}
