import Foundation

struct SurveyResponseSubmit: Codable, Sendable {
    let surveyId: String
    let type: String
    let value: SurveyResponseValue
    let appVersion: String
    let sdkVersion: String
}

enum SurveyResponseValue: Codable, Sendable {
    case int(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
            return
        }
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
            return
        }
        throw DecodingError.typeMismatch(
            SurveyResponseValue.self,
            .init(codingPath: decoder.codingPath, debugDescription: "Expected Int or String")
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}

/// Posts survey responses to `POST /v1/app/survey-responses`.
struct SurveyResponseClient: Sendable {
    private let session: URLSession
    private let timeout: TimeInterval

    init(session: URLSession = .shared, timeout: TimeInterval = 15) {
        self.session = session
        self.timeout = timeout
    }

    func submit(_ payload: SurveyResponseSubmit) async -> Bool {
        guard Configuration.shared.isConfigured else { return false }

        let snapshot = Configuration.shared.snapshot()
        guard let url = URL(string: "v1/app/survey-responses", relativeTo: snapshot.apiBaseURL),
              let body = try? JSONEncoder().encode(payload)
        else {
            return false
        }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(snapshot.apiKey, forHTTPHeaderField: "X-API-Key")
        request.httpBody = body

        do {
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return (200 ... 299).contains(http.statusCode)
        } catch {
            return false
        }
    }
}
