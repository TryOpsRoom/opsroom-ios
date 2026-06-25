import Foundation

/// Device-local eligibility state for micro surveys.
struct MicroSurveyStateStore {
    private let defaults: UserDefaults
    private let prefix: String

    private var sessionCountKey: String { "\(prefix).sessionCount" }
    private var firstLaunchKey: String { "\(prefix).firstLaunch" }
    private var lastShownSurveyIdKey: String { "\(prefix).lastShownSurveyId" }
    private var lastShownDateKey: String { "\(prefix).lastShownDate" }
    private var suppressKey: String { "\(prefix).suppress" }
    private var trackEventCountsKey: String { "\(prefix).trackEventCounts" }

    init(
        defaults: UserDefaults = .standard,
        storageKeyPrefix: String = "opsroom.microSurvey"
    ) {
        self.defaults = defaults
        self.prefix = storageKeyPrefix
    }

    var sessionCount: Int {
        defaults.integer(forKey: sessionCountKey)
    }

    var suppressSurveys: Bool {
        defaults.bool(forKey: suppressKey)
    }

    func setSuppressSurveys(_ suppress: Bool) {
        defaults.set(suppress, forKey: suppressKey)
    }

    func recordSession() {
        if defaults.object(forKey: firstLaunchKey) == nil {
            defaults.set(Date(), forKey: firstLaunchKey)
        }
        defaults.set(sessionCount + 1, forKey: sessionCountKey)
    }

    func daysSinceInstall(reference: Date = Date()) -> Int {
        guard let first = defaults.object(forKey: firstLaunchKey) as? Date else {
            return 0
        }
        return max(0, Int(reference.timeIntervalSince(first) / 86_400))
    }

    func daysSinceLastShown(reference: Date = Date()) -> Int? {
        guard let last = defaults.object(forKey: lastShownDateKey) as? Date else {
            return nil
        }
        return max(0, Int(reference.timeIntervalSince(last) / 86_400))
    }

    func lastShownSurveyId() -> String? {
        defaults.string(forKey: lastShownSurveyIdKey)
    }

    func recordShown(surveyId: String, at date: Date = Date()) {
        defaults.set(surveyId, forKey: lastShownSurveyIdKey)
        defaults.set(date, forKey: lastShownDateKey)
    }

    func trackEventCount(for name: String) -> Int {
        trackEventCounts()[name] ?? 0
    }

    func incrementTrackEvent(name: String) {
        var counts = trackEventCounts()
        counts[name] = (counts[name] ?? 0) + 1
        defaults.set(counts, forKey: trackEventCountsKey)
    }

    #if DEBUG
    func resetForTesting() {
        for key in [
            sessionCountKey,
            firstLaunchKey,
            lastShownSurveyIdKey,
            lastShownDateKey,
            suppressKey,
            trackEventCountsKey,
        ] {
            defaults.removeObject(forKey: key)
        }
    }
    #endif

    private func trackEventCounts() -> [String: Int] {
        guard let raw = defaults.dictionary(forKey: trackEventCountsKey) else {
            return [:]
        }
        var result: [String: Int] = [:]
        for (key, value) in raw {
            if let count = value as? Int {
                result[key] = count
            }
        }
        return result
    }
}
