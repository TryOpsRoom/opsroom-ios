import Foundation

/// Evaluates micro-survey eligibility and presents the survey sheet.
@MainActor
final class SurveyCoordinator {
    static let shared = SurveyCoordinator()

    private var cachedSurvey: MicroSurvey?
    private let stateStore = MicroSurveyStateStore()
    private let responseClient = SurveyResponseClient()
    private let responseQueue = SurveyResponseQueue()
    private let eventsClient = ConfigEventsClient()
    private var isPresenting = false

    private init() {}

    func recordSessionIfNeeded() {
        stateStore.recordSession()
    }

    func trackEvent(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        stateStore.incrementTrackEvent(name: trimmed)
    }

    func setSuppressSurveys(_ suppress: Bool) {
        stateStore.setSuppressSurveys(suppress)
    }

    func updateConfig(_ survey: MicroSurvey?) {
        cachedSurvey = survey
    }

    func flushQueuedResponsesIfNeeded() async {
        await responseQueue.flush(using: responseClient)
    }

    func evaluateAndPresentIfNeeded(blockedByHigherPriorityUI: Bool) async {
        guard !blockedByHigherPriorityUI else { return }
        guard let survey = cachedSurvey else { return }
        guard !isPresenting else { return }

        let evaluation = MicroSurveyEvaluator.evaluate(
            survey: survey,
            appVersion: AppInfo.appVersion,
            state: stateStore
        )
        if case .skip(let reason) = evaluation {
            OpsRoomLog.config.debug(
                "Micro survey skipped: \(reason.rawValue, privacy: .public)"
            )
            return
        }

        isPresenting = true
        let presented = await SurveyPresenter.present(
            survey: survey,
            onSubmit: { [weak self] value in
                Task { @MainActor in
                    await self?.handleSubmit(survey: survey, value: value)
                }
            },
            onDismiss: { [weak self] in
                Task { @MainActor in
                    await self?.handleDismiss(survey: survey)
                }
            }
        )
        if presented {
            stateStore.recordShown(surveyId: survey.id)
            await eventsClient.reportMicroSurvey(action: "shown", survey: survey)
        } else {
            isPresenting = false
        }
    }

    #if DEBUG
    func resetForTesting() {
        cachedSurvey = nil
        isPresenting = false
        stateStore.resetForTesting()
        responseQueue.resetForTesting()
        SurveyPresenter.dismiss()
    }
    #endif

    private func handleSubmit(survey: MicroSurvey, value: SurveyResponseValue) async {
        isPresenting = false
        let payload = SurveyResponseSubmit(
            surveyId: survey.id,
            type: survey.type.rawValue,
            value: value,
            appVersion: AppInfo.appVersion,
            sdkVersion: OpsRoomSDKVersion.current
        )
        let submitted = await responseClient.submit(payload)
        if !submitted {
            responseQueue.enqueue(payload)
        }
        await eventsClient.reportMicroSurvey(action: "submitted", survey: survey)
        recordRatingSuppressionIfNeeded(survey: survey, value: value)
    }

    private func handleDismiss(survey: MicroSurvey) async {
        isPresenting = false
        stateStore.recordShown(surveyId: survey.id)
        await eventsClient.reportMicroSurvey(action: "dismissed", survey: survey)
    }

    private func recordRatingSuppressionIfNeeded(
        survey: MicroSurvey,
        value: SurveyResponseValue
    ) {
        guard survey.type == .nps || survey.type == .csat else { return }
        guard case .int(let intValue) = value else { return }
        let normalized = normalizeSurveyScoreForRatingSuppression(
            type: survey.type,
            value: intValue
        )
        guard let score = normalized else { return }
        RatingPromptCoordinator.shared.recordSurveyResponse(score: score)
    }

    private func normalizeSurveyScoreForRatingSuppression(
        type: MicroSurvey.SurveyType,
        value: Int
    ) -> Int? {
        switch type {
        case .nps:
            return max(0, min(10, value))
        case .csat:
            let clamped = max(1, min(5, value))
            return Int((Double(clamped - 1) * 2.5).rounded())
        case .multiple_choice:
            return nil
        }
    }
}
