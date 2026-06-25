import Foundation

/// Top-level JSON body from `GET /v1/app/config`.
struct AppConfigResponse: Codable, Sendable, Equatable {
    /// Resolved upgrade action and optional prompt copy.
    let upgrade: UpgradePayload

    /// Optional active maintenance window; `nil` when the server omits maintenance.
    let maintenance: MaintenancePayload?

    /// Optional in-app announcement; `nil` when none is active.
    let announcement: Announcement?

    /// Optional rating-prompt rules; `nil` when disabled on the server.
    let ratingPrompt: RatingPrompt?

    /// Optional release notes when the app version matches server config.
    let releaseNotes: ReleaseNotes?

    /// Optional micro survey when enabled on the server.
    let survey: MicroSurvey?

    /// Optional in-app feedback form when enabled on the server.
    let feedback: FeedbackPayload?
}

/// Upgrade section of the config response.
struct UpgradePayload: Codable, Sendable, Equatable {
    /// What the SDK should do (`none`, soft prompt, or force prompt).
    let action: UpgradeAction

    /// Copy and App Store URL when ``action`` is `force`; otherwise `nil`.
    let force: UpgradeForcePrompt?

    /// Copy and App Store URL when ``action`` is `soft`; otherwise `nil`.
    let soft: UpgradeSoftPrompt?
}

/// Server-resolved upgrade action for the current app version and environment.
enum UpgradeAction: String, Codable, Sendable, Equatable {
    /// No prompt; app may continue normally.
    case none

    /// Optional update; user can dismiss via secondary action.
    case soft

    /// Required update; modal cannot be dismissed until the user opens the store.
    case force
}

/// Prompt content for a mandatory (force) upgrade.
struct UpgradeForcePrompt: Codable, Sendable, Equatable {
    let title: String
    let message: String
    let primaryLabel: String
    let appStoreURL: URL
}

/// Prompt content for an optional (soft) upgrade.
struct UpgradeSoftPrompt: Codable, Sendable, Equatable {
    let title: String
    let message: String
    let primaryLabel: String
    /// Secondary button label; SDK defaults to `"Later"` when omitted.
    let secondaryLabel: String?
    let appStoreURL: URL
}

/// Normalized model used by the upgrade UI layer after decoding.
struct UpgradePromptPresentation: Sendable, Equatable {
    /// Whether the user can dismiss the prompt without updating.
    enum Style: Sendable, Equatable {
        /// Optional update with primary (App Store) and secondary (Later) actions.
        case soft

        /// Required update; only primary action (no dismiss).
        case force
    }

    let style: Style
    let title: String
    let message: String
    let primaryLabel: String
    let secondaryLabel: String?
    let appStoreURL: URL
}

extension UpgradePayload {
    /// Maps API upgrade payload to UI presentation, or `nil` when no prompt should show.
    func presentation() -> UpgradePromptPresentation? {
        switch action {
        case .none:
            return nil
        case .force:
            guard let force else { return nil }
            return UpgradePromptPresentation(
                style: .force,
                title: force.title,
                message: force.message,
                primaryLabel: force.primaryLabel,
                secondaryLabel: nil,
                appStoreURL: force.appStoreURL
            )
        case .soft:
            guard let soft else { return nil }
            return UpgradePromptPresentation(
                style: .soft,
                title: soft.title,
                message: soft.message,
                primaryLabel: soft.primaryLabel,
                secondaryLabel: soft.secondaryLabel ?? "Later",
                appStoreURL: soft.appStoreURL
            )
        }
    }
}
