import Foundation

enum RatingPromptEvaluator {
    static let appleMaxPromptsPer365Days = 3

    static func evaluate(
        config: RatingPrompt?,
        appVersion: String,
        state: RatingPromptStateStore,
        reference: Date = Date()
    ) -> RatingPromptEvaluation {
        guard let config else {
            return .skip(.disabled)
        }

        if state.sessionCount < config.minSessions {
            return .skip(.minSessions)
        }

        if state.daysSinceInstall(reference: reference) < config.minDaysSinceInstall {
            return .skip(.minDaysSinceInstall)
        }

        if let minimum = config.minimumAppVersion?.trimmingCharacters(in: .whitespacesAndNewlines),
           !minimum.isEmpty,
           VersionComparison.compare(appVersion, minimum) < 0
        {
            return .skip(.minimumAppVersion)
        }

        if config.suppressAfterNegativeSurvey,
           let days = state.daysSinceNegativeSurvey(reference: reference),
           days < config.suppressDays
        {
            return .skip(.negativeSurveySuppression)
        }

        if let daysSinceLast = state.daysSinceLastPrompt(reference: reference),
           daysSinceLast < config.minDaysBetweenPrompts
        {
            return .skip(.minDaysBetweenPrompts)
        }

        if state.promptsInLast365Days(reference: reference) >= appleMaxPromptsPer365Days {
            return .skip(.appleAnnualLimit)
        }

        return .requestReview
    }
}
