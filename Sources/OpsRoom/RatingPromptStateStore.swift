import Foundation

/// Local engagement and prompt history for rating prompt eligibility.
struct RatingPromptStateStore {
    private let defaults: UserDefaults
    private let prefix: String

    private var sessionCountKey: String { "\(prefix).sessionCount" }
    private var firstLaunchKey: String { "\(prefix).firstLaunch" }
    private var lastPromptKey: String { "\(prefix).lastPrompt" }
    private var promptDatesKey: String { "\(prefix).promptDates" }
    private var negativeSurveyKey: String { "\(prefix).negativeSurveyAt" }

    init(
        defaults: UserDefaults = .standard,
        storageKeyPrefix: String = "opsroom.ratingPrompt"
    ) {
        self.defaults = defaults
        self.prefix = storageKeyPrefix
    }

    var sessionCount: Int {
        defaults.integer(forKey: sessionCountKey)
    }

    func recordSession() {
        if defaults.object(forKey: firstLaunchKey) == nil {
            defaults.set(Date(), forKey: firstLaunchKey)
        }
        let next = sessionCount + 1
        defaults.set(next, forKey: sessionCountKey)
    }

    func daysSinceInstall(reference: Date = Date()) -> Int {
        guard let first = defaults.object(forKey: firstLaunchKey) as? Date else {
            return 0
        }
        let interval = reference.timeIntervalSince(first)
        return max(0, Int(interval / 86_400))
    }

    func daysSinceLastPrompt(reference: Date = Date()) -> Int? {
        guard let last = defaults.object(forKey: lastPromptKey) as? Date else {
            return nil
        }
        let interval = reference.timeIntervalSince(last)
        return max(0, Int(interval / 86_400))
    }

    func recordPromptRequested(at date: Date = Date()) {
        defaults.set(date, forKey: lastPromptKey)
        var dates = promptDatesWithinLastYear(reference: date)
        dates.append(date)
        let encoded = dates.map { ISO8601DateFormatter().string(from: $0) }
        defaults.set(encoded, forKey: promptDatesKey)
    }

    func promptsInLast365Days(reference: Date = Date()) -> Int {
        promptDatesWithinLastYear(reference: reference).count
    }

    func recordNegativeSurveyResponse(at date: Date = Date()) {
        defaults.set(date, forKey: negativeSurveyKey)
    }

    func daysSinceNegativeSurvey(reference: Date = Date()) -> Int? {
        guard let at = defaults.object(forKey: negativeSurveyKey) as? Date else {
            return nil
        }
        let interval = reference.timeIntervalSince(at)
        return max(0, Int(interval / 86_400))
    }

    #if DEBUG
    func resetForTesting() {
        for key in [
            sessionCountKey,
            firstLaunchKey,
            lastPromptKey,
            promptDatesKey,
            negativeSurveyKey,
        ] {
            defaults.removeObject(forKey: key)
        }
    }
    #endif

    private func promptDatesWithinLastYear(reference: Date) -> [Date] {
        let formatter = ISO8601DateFormatter()
        let raw = defaults.stringArray(forKey: promptDatesKey) ?? []
        let oneYearAgo = reference.addingTimeInterval(-365 * 86_400)
        return raw.compactMap { formatter.date(from: $0) }
            .filter { $0 >= oneYearAgo }
    }
}
