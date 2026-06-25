import Foundation
import Testing
@testable import OpsRoom

@Suite struct AnnouncementDecodingTests {
    @Test func decodesAnnouncementPayload() throws {
        let json = """
        {
          "upgrade": {
            "action": "none",
            "force": null,
            "soft": null
          },
          "maintenance": null,
          "announcement": {
            "id": "ann_1",
            "title": "News",
            "message": "Hello there",
            "style": "modal",
            "ctaLabel": "Go",
            "ctaURL": "https://example.com"
          }
        }
        """
        let response = try JSONDecoder().decode(
            AppConfigResponse.self,
            from: Data(json.utf8)
        )
        #expect(response.announcement?.id == "ann_1")
        #expect(response.announcement?.ctaURL?.absoluteString == "https://example.com")
    }

    @Test func decodesNullAnnouncement() throws {
        let json = """
        {
          "upgrade": { "action": "none", "force": null, "soft": null },
          "maintenance": null,
          "announcement": null
        }
        """
        let response = try JSONDecoder().decode(
            AppConfigResponse.self,
            from: Data(json.utf8)
        )
        #expect(response.announcement == nil)
    }
}

@Suite struct AnnouncementShownStoreTests {
    @Test func showsOncePerId() {
        let defaults = UserDefaults(suiteName: "AnnouncementShownStoreTests")!
        defaults.removePersistentDomain(forName: "AnnouncementShownStoreTests")
        let store = AnnouncementShownStore(
            defaults: defaults,
            storageKey: "test.shown"
        )
        let announcement = Announcement(
            id: "ann_a",
            title: "T",
            message: "M",
            style: .modal
        )
        #expect(store.shouldPresent(announcement))
        store.markShown(id: announcement.id)
        #expect(!store.shouldPresent(announcement))
        #expect(store.hasShown(id: "ann_a"))
    }
}
