import Foundation

enum MicroSurveySkipReason: String, Sendable, Equatable {
    case suppressed
    case minSessions
    case minDaysSinceInstall
    case minDaysBetweenSurveys
    case minimumAppVersion
    case trackEvent
}

enum MicroSurveyEvaluation: Sendable, Equatable {
    case present
    case skip(MicroSurveySkipReason)
}

enum MicroSurveyEvaluator {
    static func evaluate(
        survey: MicroSurvey,
        appVersion: String,
        state: MicroSurveyStateStore,
        reference: Date = Date()
    ) -> MicroSurveyEvaluation {
        if state.suppressSurveys {
            return .skip(.suppressed)
        }

        if state.sessionCount < survey.minSessions {
            return .skip(.minSessions)
        }

        if state.daysSinceInstall(reference: reference) < survey.minDaysSinceInstall {
            return .skip(.minDaysSinceInstall)
        }

        if let minimum = survey.minimumAppVersion?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !minimum.isEmpty,
           VersionComparison.compare(appVersion, minimum) < 0
        {
            return .skip(.minimumAppVersion)
        }

        if let daysSince = state.daysSinceLastShown(reference: reference),
           daysSince < survey.minDaysBetweenSurveys
        {
            return .skip(.minDaysBetweenSurveys)
        }

        if let eventName = survey.trackEventName?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !eventName.isEmpty
        {
            let required = max(1, survey.trackEventCount)
            if state.trackEventCount(for: eventName) < required {
                return .skip(.trackEvent)
            }
        }

        return .present
    }
}
