import Foundation

/// Entry point for the OpsRoom iOS SDK.
///
/// Call ``configure(apiKey:environment:options:)`` once at app startup (for example in your `@main` `App` initializer).
/// The SDK fetches remote upgrade policy from your OpsRoom config API and may present soft or force update UI.
///
/// ## Topics
///
/// ### Setup
///
/// - ``configure(apiKey:environment:options:)``
/// - ``setEnvironment(_:)``
///
/// ### Upgrade checks
///
/// - ``checkForUpdates()``
///
/// ## Behavior
///
/// - **Fail open:** Network and server errors never block launch unless a **fresh** maintenance flag is active.
/// - **Cold launch:** When ``ConfigurationOptions/checkOnLaunch`` is `true`, one automatic check runs per process after configure.
/// - **Offline cache:** Last successful config is stored in UserDefaults (see ``ConfigurationOptions/enableConfigCache``). Offline: **soft** prompts only; **force** never from cache alone.
/// - **Maintenance:** Active maintenance shows a full-screen blocking UI (network response; also from cache within TTL). Checked on cold launch and foreground when ``ConfigurationOptions/checkOnForeground`` is enabled.
public enum OpsRoom {
    /// Registers the SDK with your API key and runtime environment.
    ///
    /// Safe to call from any thread. When ``ConfigurationOptions/checkOnLaunch`` is enabled, the first upgrade check
    /// is scheduled on the main actor after this returns.
    ///
    /// - Parameters:
    ///   - apiKey: Secret issued for your app in the OpsRoom dashboard. Sent as the `X-API-Key` header.
    ///   - environment: Build channel sent to the API as the `environment` query parameter. Use ``AppEnvironment/production``
    ///     for App Store builds, ``AppEnvironment/testFlight`` for TestFlight, and ``AppEnvironment/debug`` for local/debug.
    ///   - options: API base URL, bundle ID override, and launch behavior. Defaults to production API host and `checkOnLaunch: true`.
    ///
    /// - Important: Call exactly once per process before ``checkForUpdates()`` or relying on automatic launch checks.
    public static func configure(
        apiKey: String,
        environment: AppEnvironment,
        options: ConfigurationOptions = .init()
    ) {
        Configuration.shared.apply(
            apiKey: apiKey,
            environment: environment,
            options: options
        )

        if options.checkOnLaunch {
            Task { @MainActor in
                await UpgradeCoordinator.shared.performLaunchCheckIfNeeded()
            }
        }

        ForegroundConfigObserver.startIfNeeded()
    }

    /// Updates the runtime environment without changing the API key or other options.
    ///
    /// Use when the same binary can run as debug, TestFlight, or production (for example a developer menu in a sample app).
    /// The new value is included on the next config request as the `environment` query parameter.
    ///
    /// - Parameter environment: The channel to report to the server.
    ///
    /// - Precondition: ``configure(apiKey:environment:options:)`` must have been called; otherwise this triggers an assertion in debug builds.
    public static func setEnvironment(_ environment: AppEnvironment) {
        guard Configuration.shared.isConfigured else {
            assertionFailure("OpsRoom.configure(apiKey:environment:) must be called first.")
            return
        }
        Configuration.shared.setEnvironment(environment)
    }

    /// Fetches the latest config from the API and presents an upgrade prompt when the policy requires it.
    ///
    /// Also invoked automatically once per cold launch when ``ConfigurationOptions/checkOnLaunch`` is `true`.
    /// Must be called from the main actor (for example inside a `Task { @MainActor in ... }` from SwiftUI).
    ///
    /// - Note: Concurrent calls while a prompt is visible are ignored until the user dismisses or completes the soft-update flow.
    /// - Note: On failure, the SDK fails open and does not surface an error to the user.
    @MainActor
    public static func checkForUpdates() async {
        guard Configuration.shared.isConfigured else {
            assertionFailure("OpsRoom.configure(apiKey:environment:) must be called first.")
            return
        }
        await UpgradeCoordinator.shared.checkForUpdates()
    }

    /// Evaluates dashboard rules and may call `SKStoreReviewController` when appropriate.
    ///
    /// Call at a natural moment (for example after the user completes a task). The SDK uses
    /// session count, install age, spacing between prompts, optional version targeting, and
    /// Apple's limit of about three prompts per 365 days. Outcomes are reported to the API for
    /// dashboard analytics when the network is available.
    ///
    /// - Returns: Whether the SDK requested a review or skipped (with a reason).
    @MainActor
    @discardableResult
    public static func requestReviewIfAppropriate() async -> RatingPromptEvaluation {
        guard Configuration.shared.isConfigured else {
            assertionFailure("OpsRoom.configure(apiKey:environment:) must be called first.")
            return .skip(.disabled)
        }
        return await RatingPromptCoordinator.shared.requestReviewIfAppropriate()
    }

    /// Records an in-app survey score for negative-response suppression of rating prompts.
    ///
    /// When the score is at or below the dashboard's ``RatingPrompt/negativeSurveyMaxScore``,
    /// the SDK suppresses review requests for ``RatingPrompt/suppressDays`` days.
    ///
    /// - Parameter score: Numeric survey result (for example NPS 0–10).
    @MainActor
    public static func recordSurveyResponse(score: Int) {
        guard Configuration.shared.isConfigured else {
            assertionFailure("OpsRoom.configure(apiKey:environment:) must be called first.")
            return
        }
        RatingPromptCoordinator.shared.recordSurveyResponse(score: score)
    }

    /// Increments a device-local counter for custom survey trigger events.
    ///
    /// When the dashboard survey requires a ``MicroSurvey/trackEventName``, the sheet is
    /// eligible only after this count reaches ``MicroSurvey/trackEventCount``.
    ///
    /// - Parameter name: Event name matching dashboard configuration (for example `completed_export`).
    @MainActor
    public static func trackEvent(_ name: String) {
        guard Configuration.shared.isConfigured else {
            assertionFailure("OpsRoom.configure(apiKey:environment:) must be called first.")
            return
        }
        SurveyCoordinator.shared.trackEvent(name)
    }

    /// Temporarily blocks micro surveys (for example during onboarding).
    ///
    /// - Parameter suppress: When `true`, surveys are not shown until set back to `false`.
    @MainActor
    public static func suppressSurveys(_ suppress: Bool) {
        guard Configuration.shared.isConfigured else {
            assertionFailure("OpsRoom.configure(apiKey:environment:) must be called first.")
            return
        }
        SurveyCoordinator.shared.setSuppressSurveys(suppress)
    }

    /// Presents the in-app feedback sheet configured in the dashboard.
    ///
    /// Call from a settings screen or support action. Requires a prior config fetch
    /// (for example after ``checkForUpdates()``) so feedback copy is available.
    ///
    /// - Returns: Whether the sheet was presented.
    @MainActor
    @discardableResult
    public static func presentFeedback() async -> Bool {
        guard Configuration.shared.isConfigured else {
            assertionFailure("OpsRoom.configure(apiKey:environment:) must be called first.")
            return false
        }
        return await FeedbackCoordinator.shared.presentFeedback()
    }

    #if DEBUG
    /// Replaces the type that performs config HTTP requests.
    ///
    /// Use in unit tests to stub network responses without hitting the real API.
    ///
    /// - Parameter client: Type conforming to ``ConfigAPIClientProtocol``.
    @MainActor
    static func setConfigAPIClientForTesting(_ client: any ConfigAPIClientProtocol) {
        UpgradeCoordinator.shared.apiClient = client
    }

    /// Clears configuration, launch-check flags, and the default API client between tests.
    ///
    /// Call at the start of tests that invoke ``configure(apiKey:environment:options:)`` so state does not leak across cases.
    @MainActor
    static func resetLaunchCheckStateForTesting() {
        Configuration.shared.resetForTesting()
        UpgradeCoordinator.shared.resetForTesting()
        RatingPromptCoordinator.shared.resetForTesting()
        SurveyCoordinator.shared.resetForTesting()
        FeedbackCoordinator.shared.resetForTesting()
        ForegroundConfigObserver.stopForTesting()
    }
    #endif
}
