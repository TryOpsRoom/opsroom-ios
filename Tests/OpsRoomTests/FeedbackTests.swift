import Foundation
import Testing
@testable import OpsRoom

@Suite struct FeedbackResponseQueueTests {
    @Test @MainActor func enqueuePersistsPayload() {
        let defaults = UserDefaults(suiteName: "lq.feedback.\(UUID().uuidString)")!
        let queue = FeedbackResponseQueue(defaults: defaults)
        let payload = FeedbackResponseSubmit(
            message: "Great app!",
            appVersion: "1.0.0",
            sdkVersion: "0.1.0"
        )
        queue.enqueue(payload)
        #expect(defaults.data(forKey: "opsroom.feedbackResponseQueue") != nil)
    }
}

@Suite struct FeedbackStateStoreTests {
    @Test func recordsSessions() {
        let defaults = UserDefaults(suiteName: "lq.feedback.state.\(UUID().uuidString)")!
        let store = FeedbackStateStore(defaults: defaults, storageKeyPrefix: "test")
        #expect(store.sessionCount == 0)
        store.recordSession()
        store.recordSession()
        #expect(store.sessionCount == 2)
    }
}
