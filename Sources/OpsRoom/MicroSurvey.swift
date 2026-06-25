import Foundation

/// Micro survey payload from `GET /v1/app/config`.
struct MicroSurvey: Codable, Sendable, Equatable {
    enum SurveyType: String, Codable, Sendable, Equatable {
        case nps
        case csat
        case multiple_choice
    }

    let id: String
    let type: SurveyType
    let question: String
    let options: [String]?
    let minSessions: Int
    let minDaysSinceInstall: Int
    let minDaysBetweenSurveys: Int
    let minimumAppVersion: String?
    let trackEventName: String?
    let trackEventCount: Int
}
