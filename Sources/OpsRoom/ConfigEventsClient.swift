import Foundation

/// Fire-and-forget reporting of SDK outcomes to `POST /v1/app/events`.
struct ConfigEventsClient: Sendable {
    private let session: URLSession
    private let timeout: TimeInterval

    init(session: URLSession = .shared, timeout: TimeInterval = 10) {
        self.session = session
        self.timeout = timeout
    }

    func reportRatingPrompt(
        action: String,
        reason: RatingPromptSkipReason? = nil
    ) async {
        var event: [String: Any] = [
            "type": "rating_prompt",
            "action": action,
            "appVersion": AppInfo.appVersion,
            "sdkVersion": OpsRoomSDKVersion.current,
        ]
        if action == "skipped", let reason {
            event["reason"] = reason.rawValue
        }
        await post(events: [event])
    }

    func reportUpgrade(action: String, prompt: String) async {
        let event: [String: Any] = [
            "type": "upgrade",
            "action": action,
            "prompt": prompt,
            "appVersion": AppInfo.appVersion,
            "sdkVersion": OpsRoomSDKVersion.current,
        ]
        await post(events: [event])
    }

    func reportAnnouncement(action: String, announcement: Announcement) async {
        let event: [String: Any] = [
            "type": "announcement",
            "action": action,
            "announcementId": announcement.id,
            "style": announcement.style.rawValue,
            "appVersion": AppInfo.appVersion,
            "sdkVersion": OpsRoomSDKVersion.current,
        ]
        await post(events: [event])
    }

    func reportMicroSurvey(action: String, survey: MicroSurvey) async {
        let event: [String: Any] = [
            "type": "micro_survey",
            "action": action,
            "surveyId": survey.id,
            "appVersion": AppInfo.appVersion,
            "sdkVersion": OpsRoomSDKVersion.current,
        ]
        await post(events: [event])
    }

    func reportFeedback(action: String? = nil) async {
        var event: [String: Any] = [
            "type": "feedback",
            "appVersion": AppInfo.appVersion,
            "sdkVersion": OpsRoomSDKVersion.current,
        ]
        if let action {
            event["action"] = action
        }
        await post(events: [event])
    }

    private func post(events: [[String: Any]]) async {
        guard Configuration.shared.isConfigured else { return }

        let snapshot = Configuration.shared.snapshot()
        let base = snapshot.apiBaseURL
        let body: [String: Any] = ["events": events]
        guard let url = URL(string: "v1/app/events", relativeTo: base),
              let data = try? JSONSerialization.data(withJSONObject: body)
        else {
            return
        }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(snapshot.apiKey, forHTTPHeaderField: "X-API-Key")
        request.httpBody = data

        _ = try? await session.data(for: request)
    }
}
