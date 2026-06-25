import Foundation
import Testing
@testable import OpsRoom

@Suite(.serialized)
struct OpsRoomTests {
@Test @MainActor func configureSetsEnvironment() async {
    await SDKTestIsolation.shared.run {
    OpsRoom.resetLaunchCheckStateForTesting()
    OpsRoom.configure(
        apiKey: "test-key",
        environment: .production,
        options: .init(checkOnLaunch: false, bundleIdentifier: "com.example.app")
    )
    #expect(Configuration.shared.isConfigured)
    }
}

@Test @MainActor func setEnvironmentUpdatesRuntimeValue() async {
    await SDKTestIsolation.shared.run {
    OpsRoom.resetLaunchCheckStateForTesting()
    OpsRoom.configure(
        apiKey: "test-key",
        environment: .production,
        options: .init(checkOnLaunch: false, bundleIdentifier: "com.example.app")
    )
    OpsRoom.setEnvironment(.debug)
    #expect(Configuration.shared.snapshot().environment == .debug)
    }
}

@Test func decodesUpgradeResponse() throws {
    let json = """
    {
      "upgrade": {
        "action": "soft",
        "force": null,
        "soft": {
          "title": "Update Available",
          "message": "Please update.",
          "primaryLabel": "Update",
          "secondaryLabel": "Later",
          "appStoreURL": "https://apps.apple.com/app/id123"
        }
      },
      "maintenance": null
    }
    """
    let response = try JSONDecoder().decode(
        AppConfigResponse.self,
        from: Data(json.utf8)
    )
    #expect(response.upgrade.action == .soft)
    let presentation = response.upgrade.presentation()
    #expect(presentation?.style == .soft)
    #expect(presentation?.secondaryLabel == "Later")
}

@Test func presentationForceStyle() throws {
    let json = """
    {
      "upgrade": {
        "action": "force",
        "force": {
          "title": "Required",
          "message": "Update now.",
          "primaryLabel": "Update Now",
          "appStoreURL": "https://apps.apple.com/app/id123"
        },
        "soft": null
      },
      "maintenance": null
    }
    """
    let response = try JSONDecoder().decode(
        AppConfigResponse.self,
        from: Data(json.utf8)
    )
    #expect(response.upgrade.presentation()?.style == .force)
    #expect(response.upgrade.presentation()?.secondaryLabel == nil)
}

@Test @MainActor func failOpenOnNetworkError() async {
    await SDKTestIsolation.shared.run {
    OpsRoom.resetLaunchCheckStateForTesting()
    OpsRoom.configure(
        apiKey: "test-key",
        environment: .production,
        options: .init(checkOnLaunch: false, bundleIdentifier: "com.example.app")
    )
    OpsRoom.setConfigAPIClientForTesting(FailingConfigAPIClient())
    await OpsRoom.checkForUpdates()
    // No assertion for UI; succeeds if no crash and presenter not shown.
    }
}

@Test @MainActor func launchCheckRunsOnlyOnce() async {
    await SDKTestIsolation.shared.run {
    OpsRoom.resetLaunchCheckStateForTesting()
    let client = CountingConfigAPIClient()
    OpsRoom.setConfigAPIClientForTesting(client)
    OpsRoom.configure(
        apiKey: "test-key",
        environment: .production,
        options: .init(checkOnLaunch: true, bundleIdentifier: "com.example.app")
    )
    try? await Task.sleep(nanoseconds: 100_000_000)
    #expect(client.fetchCount == 1)
    await OpsRoom.checkForUpdates()
    #expect(client.fetchCount == 2)
    }
}

private struct FailingConfigAPIClient: ConfigAPIClientProtocol {
    func fetchConfig() async throws -> AppConfigResponse {
        throw ConfigAPIError.httpStatus(500)
    }
}

private final class CountingConfigAPIClient: ConfigAPIClientProtocol, @unchecked Sendable {
    private(set) var fetchCount = 0

    func fetchConfig() async throws -> AppConfigResponse {
        fetchCount += 1
        return AppConfigResponse(
            upgrade: UpgradePayload(action: .none, force: nil, soft: nil),
            maintenance: nil,
            announcement: nil,
            ratingPrompt: nil,
            releaseNotes: nil,
            survey: nil,
            feedback: nil
        )
    }
}
}

