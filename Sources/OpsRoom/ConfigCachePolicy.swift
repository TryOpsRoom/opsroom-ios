import Foundation

/// Whether config came from the network or from on-device cache.
enum ConfigResponseSource: Sendable {
    case network
    case cache
}

/// Rules for applying a cached config response (stricter than a live network response).
enum ConfigCachePolicy {
    /// Maintenance may be shown from cache when still within TTL (server already declared downtime).
    static func maintenanceToPresent(
        _ response: AppConfigResponse
    ) -> MaintenancePayload? {
        response.maintenance
    }

    /// Cached upgrade prompts: **soft only**. Force is never shown from cache alone.
    static func upgradePresentationFromCache(
        _ response: AppConfigResponse
    ) -> UpgradePromptPresentation? {
        guard let presentation = response.upgrade.presentation() else {
            return nil
        }
        switch presentation.style {
        case .soft:
            return presentation
        case .force:
            return nil
        }
    }
}
