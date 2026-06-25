import Foundation
import Testing
@testable import OpsRoom

@Suite struct ConfigCachePolicyTests {
    private let softURL = URL(string: "https://apps.apple.com/app/id1")!
    private let forceURL = URL(string: "https://apps.apple.com/app/id2")!

    @Test func cacheSuppressesForceUpgrade() {
        let response = AppConfigResponse(
            upgrade: UpgradePayload(
                action: .force,
                force: UpgradeForcePrompt(
                    title: "Required",
                    message: "Update",
                    primaryLabel: "Go",
                    appStoreURL: forceURL
                ),
                soft: nil
            ),
            maintenance: nil,
            announcement: nil,
            ratingPrompt: nil,
            releaseNotes: nil,
            survey: nil,
            feedback: nil
        )
        #expect(ConfigCachePolicy.upgradePresentationFromCache(response) == nil)
    }

    @Test func cacheAllowsSoftUpgrade() {
        let response = AppConfigResponse(
            upgrade: UpgradePayload(
                action: .soft,
                force: nil,
                soft: UpgradeSoftPrompt(
                    title: "Update",
                    message: "Please update",
                    primaryLabel: "Update",
                    secondaryLabel: "Later",
                    appStoreURL: softURL
                )
            ),
            maintenance: nil,
            announcement: nil,
            ratingPrompt: nil,
            releaseNotes: nil,
            survey: nil,
            feedback: nil
        )
        let presentation = ConfigCachePolicy.upgradePresentationFromCache(response)
        #expect(presentation?.style == .soft)
    }

    @Test func cacheAllowsActiveMaintenance() {
        let response = AppConfigResponse(
            upgrade: UpgradePayload(action: .none, force: nil, soft: nil),
            maintenance: MaintenancePayload(
                title: "Down",
                message: "Back soon"
            ),
            announcement: nil,
            ratingPrompt: nil,
            releaseNotes: nil,
            survey: nil,
            feedback: nil
        )
        #expect(ConfigCachePolicy.maintenanceToPresent(response)?.title == "Down")
    }
}

@Suite struct ConfigCacheStoreTests {
    @Test func roundTripSaveAndLoad() {
        let suiteName = "com.opsroom.sdk.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        ConfigCacheStore.defaultsOverride = defaults
        defer {
            ConfigCacheStore.defaultsOverride = nil
            defaults.removePersistentDomain(forName: suiteName)
        }

        let url = URL(string: "https://apps.apple.com/app/id1")!
        let response = AppConfigResponse(
            upgrade: UpgradePayload(
                action: .soft,
                force: nil,
                soft: UpgradeSoftPrompt(
                    title: "T",
                    message: "M",
                    primaryLabel: "P",
                    secondaryLabel: "L",
                    appStoreURL: url
                )
            ),
            maintenance: nil,
            announcement: nil,
            ratingPrompt: nil,
            releaseNotes: nil,
            survey: nil,
            feedback: nil
        )

        ConfigCacheStore.save(response, bundleIdentifier: "com.test.cache")
        let loaded = ConfigCacheStore.load(bundleIdentifier: "com.test.cache")
        #expect(loaded?.response.upgrade.action == .soft)
        #expect(ConfigCacheStore.isValid(entry: loaded!, ttl: 3600))
    }
}
