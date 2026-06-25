import Foundation

/// In-app feedback payload from `GET /v1/app/config`.
struct FeedbackPayload: Codable, Sendable, Equatable {
    let title: String
    let message: String
    let placeholder: String
    let submitLabel: String
    /// Minimum sessions before ``FeedbackCoordinator/presentFeedbackIfEnabled()`` may present.
    let minSessions: Int?

    init(
        title: String,
        message: String,
        placeholder: String,
        submitLabel: String,
        minSessions: Int? = nil
    ) {
        self.title = title
        self.message = message
        self.placeholder = placeholder
        self.submitLabel = submitLabel
        self.minSessions = minSessions
    }
}

struct FeedbackResponseSubmit: Codable, Sendable, Equatable {
    let message: String
    let appVersion: String
    let sdkVersion: String
}
