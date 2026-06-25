import Foundation
import Testing
@testable import OpsRoom

@Suite struct ReleaseNotesDecodingTests {
    @Test func decodesReleaseNotesFromConfig() throws {
        let json = """
        {
          "upgrade": { "action": "none", "force": null, "soft": null },
          "maintenance": null,
          "announcement": null,
          "ratingPrompt": null,
          "releaseNotes": {
            "version": "2.1.0",
            "content": "## What's new\\n- Dark mode",
            "style": "sheet"
          }
        }
        """
        let response = try JSONDecoder().decode(
            AppConfigResponse.self,
            from: Data(json.utf8)
        )
        #expect(response.releaseNotes?.version == "2.1.0")
        #expect(response.releaseNotes?.style == .sheet)
    }
}

@Suite struct ReleaseNotesShownStoreTests {
    @Test func showsOncePerVersion() {
        let suite = UserDefaults(suiteName: "lq.release.\(UUID().uuidString)")!
        let store = ReleaseNotesShownStore(defaults: suite, storageKey: "test")
        let notes = ReleaseNotes(version: "2.0.0", content: "Hello", style: .modal)
        #expect(store.shouldPresent(notes))
        store.markShown(version: notes.version)
        #expect(!store.shouldPresent(notes))
    }
}
