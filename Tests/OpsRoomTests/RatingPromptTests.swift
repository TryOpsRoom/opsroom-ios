import Foundation
import Testing
@testable import OpsRoom

@Suite struct RatingPromptDecodingTests {
    @Test func decodesRatingPromptFromConfig() throws {
        let json = """
        {
          "upgrade": { "action": "none", "force": null, "soft": null },
          "maintenance": null,
          "announcement": null,
          "releaseNotes": null,
          "ratingPrompt": {
            "minSessions": 5,
            "minDaysSinceInstall": 3,
            "minDaysBetweenPrompts": 30,
            "minimumAppVersion": "2.0.0",
            "suppressAfterNegativeSurvey": true,
            "suppressDays": 14,
            "negativeSurveyMaxScore": 6
          }
        }
        """
        let response = try JSONDecoder().decode(
            AppConfigResponse.self,
            from: Data(json.utf8)
        )
        #expect(response.ratingPrompt?.minSessions == 5)
        #expect(response.ratingPrompt?.minimumAppVersion == "2.0.0")
    }
}

@Suite struct RatingPromptEvaluatorTests {
    @Test func skipsWhenBelowMinSessions() {
        let config = RatingPrompt(
            minSessions: 10,
            minDaysSinceInstall: 0,
            minDaysBetweenPrompts: 1,
            minimumAppVersion: nil,
            suppressAfterNegativeSurvey: false,
            suppressDays: 0,
            negativeSurveyMaxScore: 6
        )
        let store = RatingPromptStateStore(
            defaults: UserDefaults(suiteName: "lq.rating.\(UUID().uuidString)")!,
            storageKeyPrefix: "test"
        )
        store.recordSession()
        let result = RatingPromptEvaluator.evaluate(
            config: config,
            appVersion: "3.0.0",
            state: store
        )
        #expect(result == .skip(.minSessions))
    }

    @Test func requestsWhenEligible() {
        let config = RatingPrompt(
            minSessions: 1,
            minDaysSinceInstall: 0,
            minDaysBetweenPrompts: 0,
            minimumAppVersion: nil,
            suppressAfterNegativeSurvey: false,
            suppressDays: 0,
            negativeSurveyMaxScore: 6
        )
        let suite = UserDefaults(suiteName: "lq.rating.\(UUID().uuidString)")!
        let store = RatingPromptStateStore(defaults: suite, storageKeyPrefix: "test")
        store.recordSession()
        let result = RatingPromptEvaluator.evaluate(
            config: config,
            appVersion: "3.0.0",
            state: store,
            reference: Date()
        )
        #expect(result == .requestReview)
    }

    @Test func skipsBelowMinimumAppVersion() {
        let config = RatingPrompt(
            minSessions: 0,
            minDaysSinceInstall: 0,
            minDaysBetweenPrompts: 0,
            minimumAppVersion: "3.0.0",
            suppressAfterNegativeSurvey: false,
            suppressDays: 0,
            negativeSurveyMaxScore: 6
        )
        let store = RatingPromptStateStore(
            defaults: UserDefaults(suiteName: "lq.rating.\(UUID().uuidString)")!,
            storageKeyPrefix: "test"
        )
        let result = RatingPromptEvaluator.evaluate(
            config: config,
            appVersion: "2.9.0",
            state: store
        )
        #expect(result == .skip(.minimumAppVersion))
    }
}

@Suite struct VersionComparisonTests {
    @Test func comparesSemver() {
        #expect(VersionComparison.compare("2.0.0", "3.0.0") < 0)
        #expect(VersionComparison.compare("3.1.0", "3.0.9") > 0)
        #expect(VersionComparison.compare("1.0", "1.0.0") == 0)
    }
}
