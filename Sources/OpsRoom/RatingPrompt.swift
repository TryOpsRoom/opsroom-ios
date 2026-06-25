import Foundation

/// Remote rating-prompt rules from `GET /v1/app/config` (`ratingPrompt` field).
public struct RatingPrompt: Codable, Sendable, Equatable {
    public let minSessions: Int
    public let minDaysSinceInstall: Int
    public let minDaysBetweenPrompts: Int
    public let minimumAppVersion: String?
    public let suppressAfterNegativeSurvey: Bool
    public let suppressDays: Int
    public let negativeSurveyMaxScore: Int
}

/// Result of ``OpsRoom/requestReviewIfAppropriate()``.
public enum RatingPromptEvaluation: Sendable, Equatable {
    case requestReview
    case skip(RatingPromptSkipReason)
}

/// Why the SDK chose not to call `SKStoreReviewController`.
public enum RatingPromptSkipReason: String, Sendable, Equatable {
    case disabled
    case minSessions
    case minDaysSinceInstall
    case minDaysBetweenPrompts
    case minimumAppVersion
    case negativeSurveySuppression
    case appleAnnualLimit
}
