import Foundation

/// Orchestrates config fetch, cache, maintenance UI, and upgrade prompts on the main actor.
@MainActor
final class UpgradeCoordinator {
    static let shared = UpgradeCoordinator()

    /// HTTP client used for config fetch (swappable in debug tests).
    var apiClient: any ConfigAPIClientProtocol = ConfigAPIClient()
    private var didRunLaunchCheck = false
    private var isPresentingPrompt = false
    private var isPresentingMaintenance = false
    private var isPresentingReleaseNotes = false
    private var isPresentingAnnouncement = false
    private let releaseNotesStore = ReleaseNotesShownStore()
    private let announcementStore = AnnouncementShownStore()
    private let eventsClient = ConfigEventsClient()

    private init() {}

    /// Runs ``checkForUpdates()`` at most once per process (cold-launch path).
    func performLaunchCheckIfNeeded() async {
        guard !didRunLaunchCheck else { return }
        didRunLaunchCheck = true
        RatingPromptCoordinator.shared.recordSessionIfNeeded()
        SurveyCoordinator.shared.recordSessionIfNeeded()
        FeedbackCoordinator.shared.recordSessionIfNeeded()
        await SurveyCoordinator.shared.flushQueuedResponsesIfNeeded()
        await FeedbackCoordinator.shared.flushQueuedResponsesIfNeeded()
        await checkForUpdates()
    }

    /// Fetches remote config (or uses a recent cache when offline) and presents UI when required.
    func checkForUpdates() async {
        guard Configuration.shared.isConfigured else { return }

        let configuration = Configuration.shared.snapshot()
        guard let bundleId = configuration.bundleIdentifier ?? AppInfo.bundleIdentifier else {
            OpsRoomLog.config.debug("Missing bundle identifier; skipping config check.")
            return
        }

        do {
            let response = try await apiClient.fetchConfig()
            if configuration.enableConfigCache {
                ConfigCacheStore.save(response, bundleIdentifier: bundleId)
            }
            await applyResponse(response, source: .network)
        } catch {
            if configuration.enableConfigCache,
               let cached = ConfigCacheStore.load(bundleIdentifier: bundleId),
               ConfigCacheStore.isValid(entry: cached, ttl: configuration.configCacheTTL)
            {
                OpsRoomLog.config.info(
                    "Using cached config (offline); force upgrades suppressed."
                )
                await applyResponse(cached.response, source: .cache)
            } else {
                OpsRoomLog.config.debug(
                    "Config fetch failed; failing open: \(String(describing: error), privacy: .public)"
                )
            }
        }
    }

    #if DEBUG
    /// Resets launch-check and presentation flags between unit tests.
    func resetForTesting() {
        didRunLaunchCheck = false
        isPresentingPrompt = false
        isPresentingMaintenance = false
        isPresentingReleaseNotes = false
        isPresentingAnnouncement = false
        apiClient = ConfigAPIClient()
        releaseNotesStore.resetForTesting()
        announcementStore.resetForTesting()
        if let bundleId = Configuration.shared.snapshot().bundleIdentifier
            ?? AppInfo.bundleIdentifier
        {
            ConfigCacheStore.clear(bundleIdentifier: bundleId)
        }
        MaintenanceModePresenter.dismiss()
        UpgradePromptPresenter.dismiss()
        ReleaseNotesPresenter.dismiss()
        AnnouncementPresenter.dismiss()
        RatingPromptCoordinator.shared.resetForTesting()
        SurveyCoordinator.shared.resetForTesting()
        FeedbackCoordinator.shared.resetForTesting()
        ForegroundConfigObserver.stopForTesting()
    }
    #endif

    private func applyResponse(
        _ response: AppConfigResponse,
        source: ConfigResponseSource
    ) async {
        RatingPromptCoordinator.shared.updateConfig(response.ratingPrompt)
        SurveyCoordinator.shared.updateConfig(response.survey)
        FeedbackCoordinator.shared.updateConfig(response.feedback)

        switch source {
        case .network:
            if let maintenance = response.maintenance {
                await presentMaintenance(maintenance)
                return
            }
            dismissMaintenanceIfNeeded()
            if let presentation = response.upgrade.presentation() {
                await presentUpgradeThenFollowUps(
                    presentation,
                    releaseNotes: response.releaseNotes,
                    announcement: response.announcement,
                    survey: response.survey
                )
            } else {
                await presentReleaseNotesThenAnnouncement(
                    releaseNotes: response.releaseNotes,
                    announcement: response.announcement,
                    survey: response.survey
                )
            }

        case .cache:
            if let maintenance = ConfigCachePolicy.maintenanceToPresent(response) {
                await presentMaintenance(maintenance)
                return
            }
            if let presentation = ConfigCachePolicy.upgradePresentationFromCache(
                response
            ) {
                await presentUpgradeThenFollowUps(
                    presentation,
                    releaseNotes: response.releaseNotes,
                    announcement: response.announcement,
                    survey: response.survey
                )
            } else {
                await presentReleaseNotesThenAnnouncement(
                    releaseNotes: response.releaseNotes,
                    announcement: response.announcement,
                    survey: response.survey
                )
            }
        }
    }

    private func presentMaintenance(_ maintenance: MaintenancePayload) async {
        guard !isPresentingMaintenance else { return }
        isPresentingMaintenance = true
        UpgradePromptPresenter.dismiss()
        isPresentingPrompt = false
        ReleaseNotesPresenter.dismiss()
        isPresentingReleaseNotes = false
        AnnouncementPresenter.dismiss()
        isPresentingAnnouncement = false
        MaintenanceModePresenter.present(maintenance)
    }

    private func dismissMaintenanceIfNeeded() {
        guard isPresentingMaintenance else { return }
        MaintenanceModePresenter.dismiss()
        isPresentingMaintenance = false
    }

    private func presentUpgradeThenFollowUps(
        _ presentation: UpgradePromptPresentation,
        releaseNotes: ReleaseNotes?,
        announcement: Announcement?,
        survey: MicroSurvey?
    ) async {
        guard !isPresentingPrompt, !isPresentingMaintenance else { return }

        isPresentingPrompt = true
        ReleaseNotesPresenter.dismiss()
        isPresentingReleaseNotes = false
        AnnouncementPresenter.dismiss()
        isPresentingAnnouncement = false

        let promptKind = presentation.style == .soft ? "soft" : "force"
        await eventsClient.reportUpgrade(action: "shown", prompt: promptKind)

        UpgradePromptPresenter.present(
            presentation,
            onPrimary: { [weak self] in
                Task { @MainActor in
                    guard let self else { return }
                    await self.eventsClient.reportUpgrade(
                        action: "update_tapped",
                        prompt: promptKind
                    )
                    if presentation.style == .soft {
                        self.isPresentingPrompt = false
                        await self.presentReleaseNotesThenAnnouncement(
                            releaseNotes: releaseNotes,
                            announcement: announcement,
                            survey: survey
                        )
                    }
                }
            },
            onSecondary: presentation.style == .soft
                ? { [weak self] in
                    Task { @MainActor in
                        guard let self else { return }
                        await self.eventsClient.reportUpgrade(
                            action: "dismissed",
                            prompt: promptKind
                        )
                        self.isPresentingPrompt = false
                        await self.presentReleaseNotesThenAnnouncement(
                            releaseNotes: releaseNotes,
                            announcement: announcement,
                            survey: survey
                        )
                    }
                }
                : nil,
            onUnavailable: { [weak self] in
                Task { @MainActor in
                    guard let self else { return }
                    self.isPresentingPrompt = false
                    await self.presentReleaseNotesThenAnnouncement(
                        releaseNotes: releaseNotes,
                        announcement: announcement,
                        survey: survey
                    )
                }
            }
        )
    }

    private func presentReleaseNotesThenAnnouncement(
        releaseNotes: ReleaseNotes?,
        announcement: Announcement?,
        survey: MicroSurvey?
    ) async {
        guard !isPresentingMaintenance, !isPresentingPrompt else { return }

        if let releaseNotes, !isPresentingReleaseNotes,
           releaseNotesStore.shouldPresent(releaseNotes)
        {
            isPresentingReleaseNotes = true
            AnnouncementPresenter.dismiss()
            isPresentingAnnouncement = false
            let presented = await ReleaseNotesPresenter.present(releaseNotes) {
                [weak self] in
                Task { @MainActor in
                    guard let self else { return }
                    self.releaseNotesStore.markShown(version: releaseNotes.version)
                    self.isPresentingReleaseNotes = false
                    await self.presentAnnouncementIfNeeded(
                        announcement,
                        survey: survey
                    )
                }
            }
            if !presented {
                isPresentingReleaseNotes = false
            }
            return
        }

        await presentAnnouncementIfNeeded(announcement, survey: survey)
    }

    private func presentAnnouncementIfNeeded(
        _ announcement: Announcement?,
        survey: MicroSurvey?
    ) async {
        if announcement == nil {
            await presentSurveyIfNeeded(survey)
            return
        }
        guard let announcement else { return }
        guard !isPresentingMaintenance, !isPresentingPrompt else { return }
        guard !isPresentingReleaseNotes else { return }
        guard !isPresentingAnnouncement else { return }
        guard announcementStore.shouldPresent(announcement) else {
            await presentSurveyIfNeeded(survey)
            return
        }

        isPresentingAnnouncement = true
        let presented = await AnnouncementPresenter.present(
            announcement,
            onDismiss: { [weak self] in
                guard let self else { return }
                self.announcementStore.markShown(id: announcement.id)
                self.isPresentingAnnouncement = false
                Task {
                    await self.eventsClient.reportAnnouncement(
                        action: "dismissed",
                        announcement: announcement
                    )
                    await self.presentSurveyIfNeeded(survey)
                }
            },
            onCTA: { [weak self] in
                guard let self else { return }
                self.announcementStore.markShown(id: announcement.id)
                self.isPresentingAnnouncement = false
                Task {
                    await self.eventsClient.reportAnnouncement(
                        action: "cta_tapped",
                        announcement: announcement
                    )
                    await self.presentSurveyIfNeeded(survey)
                }
            }
        )
        if presented {
            await eventsClient.reportAnnouncement(action: "shown", announcement: announcement)
        } else {
            isPresentingAnnouncement = false
            await presentSurveyIfNeeded(survey)
        }
    }

    private func presentSurveyIfNeeded(_ survey: MicroSurvey?) async {
        guard survey != nil else { return }
        let blocked = isPresentingMaintenance
            || isPresentingPrompt
            || isPresentingReleaseNotes
            || isPresentingAnnouncement
        await SurveyCoordinator.shared.evaluateAndPresentIfNeeded(
            blockedByHigherPriorityUI: blocked
        )
    }
}
