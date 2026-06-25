import Foundation
import Testing
@testable import OpsRoom

@Suite struct MicroSurveyDecodingTests {
    @Test func decodesSurveyFromConfig() throws {
        let json = """
        {
          "upgrade": { "action": "none", "force": null, "soft": null },
          "maintenance": null,
          "announcement": null,
          "releaseNotes": null,
          "ratingPrompt": null,
          "survey": {
            "id": "survey_test",
            "type": "nps",
            "question": "How are we doing?",
            "minSessions": 2,
            "minDaysSinceInstall": 1,
            "minDaysBetweenSurveys": 30,
            "trackEventCount": 2,
            "trackEventName": "completed_export"
          }
        }
        """
        let response = try JSONDecoder().decode(
            AppConfigResponse.self,
            from: Data(json.utf8)
        )
        #expect(response.survey?.id == "survey_test")
        #expect(response.survey?.trackEventCount == 2)
    }
}

@Suite struct MicroSurveyEvaluatorTests {
    private func sampleSurvey(
        trackEventName: String? = nil,
        trackEventCount: Int = 1
    ) -> MicroSurvey {
        MicroSurvey(
            id: "survey_test",
            type: .nps,
            question: "Rate us",
            options: nil,
            minSessions: 2,
            minDaysSinceInstall: 0,
            minDaysBetweenSurveys: 1,
            minimumAppVersion: nil,
            trackEventName: trackEventName,
            trackEventCount: trackEventCount
        )
    }

    @Test func skipsWhenBelowMinSessions() {
        let defaults = UserDefaults(suiteName: "lq.survey.\(UUID().uuidString)")!
        let store = MicroSurveyStateStore(defaults: defaults, storageKeyPrefix: "test")
        store.recordSession()
        let result = MicroSurveyEvaluator.evaluate(
            survey: sampleSurvey(),
            appVersion: "1.0.0",
            state: store
        )
        #expect(result == .skip(.minSessions))
    }

    @Test func skipsUntilTrackEventCountReached() {
        let defaults = UserDefaults(suiteName: "lq.survey.\(UUID().uuidString)")!
        let store = MicroSurveyStateStore(defaults: defaults, storageKeyPrefix: "test")
        store.recordSession()
        store.recordSession()
        let survey = sampleSurvey(trackEventName: "done", trackEventCount: 2)
        let before = MicroSurveyEvaluator.evaluate(
            survey: survey,
            appVersion: "1.0.0",
            state: store
        )
        #expect(before == .skip(.trackEvent))
        store.incrementTrackEvent(name: "done")
        store.incrementTrackEvent(name: "done")
        let after = MicroSurveyEvaluator.evaluate(
            survey: survey,
            appVersion: "1.0.0",
            state: store
        )
        #expect(after == .present)
    }

    @Test func skipsWhenGloballySuppressed() {
        let defaults = UserDefaults(suiteName: "lq.survey.\(UUID().uuidString)")!
        let store = MicroSurveyStateStore(defaults: defaults, storageKeyPrefix: "test")
        store.setSuppressSurveys(true)
        store.recordSession()
        store.recordSession()
        let result = MicroSurveyEvaluator.evaluate(
            survey: sampleSurvey(),
            appVersion: "1.0.0",
            state: store
        )
        #expect(result == .skip(.suppressed))
    }
}

@Suite struct SurveyResponseQueueTests {
    @Test @MainActor func enqueuePersistsPayload() {
        let defaults = UserDefaults(suiteName: "lq.queue.\(UUID().uuidString)")!
        let queue = SurveyResponseQueue(defaults: defaults)
        let payload = SurveyResponseSubmit(
            surveyId: "survey_1",
            type: "nps",
            value: .int(9),
            appVersion: "1.0.0",
            sdkVersion: "0.1.0"
        )
        queue.enqueue(payload)
        #expect(defaults.data(forKey: "opsroom.surveyResponseQueue") != nil)
    }
}
