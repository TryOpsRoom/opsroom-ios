import Foundation
import Testing
@testable import OpsRoom

@Suite struct ConfigResponseDecodingTests {
    @Test func decodesUpgradeWithNullMaintenance() throws {
        let json = """
        {
          "upgrade": {
            "action": "none",
            "force": null,
            "soft": null
          },
          "maintenance": null,
          "feedback": null
        }
        """
        let response = try JSONDecoder().decode(
            AppConfigResponse.self,
            from: Data(json.utf8)
        )
        #expect(response.upgrade.action == .none)
        #expect(response.maintenance == nil)
        #expect(response.feedback == nil)
    }

    @Test func decodesActiveMaintenancePayload() throws {
        let json = """
        {
          "upgrade": {
            "action": "none",
            "force": null,
            "soft": null
          },
          "maintenance": {
            "active": true,
            "title": "Back soon",
            "message": "We are upgrading servers."
          }
        }
        """
        let response = try JSONDecoder().decode(
            AppConfigResponse.self,
            from: Data(json.utf8)
        )
        #expect(response.maintenance?.active == true)
        #expect(response.maintenance?.title == "Back soon")
        #expect(response.maintenance?.endsAt == nil)
    }

    @Test func decodesMaintenanceWithSupportURLAndEndsAt() throws {
        let json = """
        {
          "upgrade": {
            "action": "none",
            "force": null,
            "soft": null
          },
          "maintenance": {
            "active": true,
            "title": "Maintenance",
            "message": "Try again later.",
            "supportURL": "https://status.example.com",
            "endsAt": "2026-06-12T18:00:00.000Z"
          }
        }
        """
        let response = try JSONDecoder().decode(
            AppConfigResponse.self,
            from: Data(json.utf8)
        )
        #expect(response.maintenance?.active == true)
        #expect(response.maintenance?.supportURL?.absoluteString == "https://status.example.com")
        #expect(response.maintenance?.endsAt == "2026-06-12T18:00:00.000Z")
    }

    @Test func decodesFeedbackPayload() throws {
        let json = """
        {
          "upgrade": {
            "action": "none",
            "force": null,
            "soft": null
          },
          "maintenance": null,
          "feedback": {
            "title": "Send feedback",
            "message": "Tell us what you think.",
            "placeholder": "Your feedback…",
            "submitLabel": "Send",
            "minSessions": 3
          }
        }
        """
        let response = try JSONDecoder().decode(
            AppConfigResponse.self,
            from: Data(json.utf8)
        )
        #expect(response.feedback?.title == "Send feedback")
        #expect(response.feedback?.submitLabel == "Send")
        #expect(response.feedback?.minSessions == 3)
    }
}
