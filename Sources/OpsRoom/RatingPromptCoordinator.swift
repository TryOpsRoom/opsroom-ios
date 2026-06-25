import Foundation
import StoreKit
#if canImport(UIKit)
import UIKit
#endif

/// Holds the latest rating-prompt config and evaluates review eligibility.
@MainActor
final class RatingPromptCoordinator {
    static let shared = RatingPromptCoordinator()

    private var cachedConfig: RatingPrompt?
    private let stateStore = RatingPromptStateStore()
    private let eventsClient = ConfigEventsClient()

    private init() {}

    func updateConfig(_ config: RatingPrompt?) {
        cachedConfig = config
    }

    func recordSessionIfNeeded() {
        stateStore.recordSession()
    }

    /// Records a survey score; marks suppression when at or below the configured threshold.
    func recordSurveyResponse(score: Int) {
        guard let config = cachedConfig else { return }
        if score <= config.negativeSurveyMaxScore {
            stateStore.recordNegativeSurveyResponse()
        }
    }

    @discardableResult
    func requestReviewIfAppropriate() async -> RatingPromptEvaluation {
        let evaluation = RatingPromptEvaluator.evaluate(
            config: cachedConfig,
            appVersion: AppInfo.appVersion,
            state: stateStore
        )

        switch evaluation {
        case .requestReview:
            stateStore.recordPromptRequested()
            requestReviewInCurrentScene()
            await eventsClient.reportRatingPrompt(action: "requested")
            OpsRoomLog.config.info("Rating prompt: requested review.")
        case .skip(let reason):
            await eventsClient.reportRatingPrompt(action: "skipped", reason: reason)
            OpsRoomLog.config.debug(
                "Rating prompt skipped: \(reason.rawValue, privacy: .public)"
            )
        }

        return evaluation
    }

    #if DEBUG
    func resetForTesting() {
        cachedConfig = nil
        stateStore.resetForTesting()
    }
    #endif

    private func requestReviewInCurrentScene() {
        #if canImport(UIKit)
        guard let scene = OverlayWindowScene.foreground() else {
            OpsRoomLog.config.debug(
                "Rating prompt skipped: no foreground window scene."
            )
            return
        }
        SKStoreReviewController.requestReview(in: scene)
        #endif
    }
}
