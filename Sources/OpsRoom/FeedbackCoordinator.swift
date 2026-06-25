import Foundation

/// Presents in-app feedback and submits responses to the API.
@MainActor
final class FeedbackCoordinator {
    static let shared = FeedbackCoordinator()

    private var cachedFeedback: FeedbackPayload?
    private let stateStore = FeedbackStateStore()
    private let responseClient = FeedbackResponseClient()
    private let responseQueue = FeedbackResponseQueue()
    private let eventsClient = ConfigEventsClient()
    private var isPresenting = false

    private init() {}

    func recordSessionIfNeeded() {
        stateStore.recordSession()
    }

    func updateConfig(_ feedback: FeedbackPayload?) {
        cachedFeedback = feedback
    }

    func flushQueuedResponsesIfNeeded() async {
        await responseQueue.flush(using: responseClient)
    }

    /// Presents feedback using the latest config payload when available.
    @discardableResult
    func presentFeedback() async -> Bool {
        guard let feedback = cachedFeedback else {
            OpsRoomLog.config.debug("Feedback skipped: not configured on server.")
            return false
        }
        return await presentSheet(feedback: feedback)
    }

    /// Presents feedback when enabled in config and session eligibility is met.
    @discardableResult
    func presentFeedbackIfEnabled() async -> Bool {
        guard let feedback = cachedFeedback else { return false }
        let minSessions = feedback.minSessions ?? 0
        guard stateStore.sessionCount >= minSessions else {
            OpsRoomLog.config.debug(
                "Feedback skipped: below minSessions (\(minSessions, privacy: .public))."
            )
            return false
        }
        return await presentSheet(feedback: feedback)
    }

    #if DEBUG
    func resetForTesting() {
        cachedFeedback = nil
        isPresenting = false
        stateStore.resetForTesting()
        responseQueue.resetForTesting()
        FeedbackPresenter.dismiss()
    }
    #endif

    private func presentSheet(feedback: FeedbackPayload) async -> Bool {
        guard !isPresenting else { return false }

        isPresenting = true
        let presented = await FeedbackPresenter.present(
            feedback: feedback,
            onSubmit: { [weak self] message in
                Task { @MainActor in
                    await self?.handleSubmit(message: message)
                }
            },
            onDismiss: { [weak self] in
                Task { @MainActor in
                    await self?.handleDismiss()
                }
            }
        )
        if presented {
            await eventsClient.reportFeedback(action: "shown")
        } else {
            isPresenting = false
        }
        return presented
    }

    private func handleSubmit(message: String) async {
        isPresenting = false
        let payload = FeedbackResponseSubmit(
            message: message,
            appVersion: AppInfo.appVersion,
            sdkVersion: OpsRoomSDKVersion.current
        )
        let submitted = await responseClient.submit(payload)
        if !submitted {
            responseQueue.enqueue(payload)
        }
        await eventsClient.reportFeedback(action: "submitted")
    }

    private func handleDismiss() async {
        isPresenting = false
        await eventsClient.reportFeedback(action: "dismissed")
    }
}
