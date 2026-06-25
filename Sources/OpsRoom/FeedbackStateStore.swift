import Foundation

/// Device-local session count for feedback eligibility.
struct FeedbackStateStore {
    private let defaults: UserDefaults
    private let sessionCountKey: String

    init(
        defaults: UserDefaults = .standard,
        storageKeyPrefix: String = "opsroom.feedback"
    ) {
        self.defaults = defaults
        self.sessionCountKey = "\(storageKeyPrefix).sessionCount"
    }

    var sessionCount: Int {
        defaults.integer(forKey: sessionCountKey)
    }

    func recordSession() {
        defaults.set(sessionCount + 1, forKey: sessionCountKey)
    }

    #if DEBUG
    func resetForTesting() {
        defaults.removeObject(forKey: sessionCountKey)
    }
    #endif
}
