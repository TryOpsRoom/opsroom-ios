import Foundation

/// Posts feedback responses to `POST /v1/app/feedback-responses`.
struct FeedbackResponseClient: Sendable {
    private let session: URLSession
    private let timeout: TimeInterval

    init(session: URLSession = .shared, timeout: TimeInterval = 15) {
        self.session = session
        self.timeout = timeout
    }

    func submit(_ payload: FeedbackResponseSubmit) async -> Bool {
        guard Configuration.shared.isConfigured else { return false }

        let snapshot = Configuration.shared.snapshot()
        guard let url = URL(string: "v1/app/feedback-responses", relativeTo: snapshot.apiBaseURL),
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
