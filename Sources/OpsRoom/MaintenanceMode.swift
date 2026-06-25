import Foundation

/// Server-driven maintenance window returned in the config API `maintenance` field.
///
/// When present, maintenance is active. The SDK presents a full-screen blocking UI using
/// ``title``, ``message``, optional ``supportURL``, and optional ``endsAt``.
public struct MaintenancePayload: Codable, Sendable, Equatable {
    /// Always `true` when the server includes a maintenance payload.
    public let active: Bool

    /// Headline shown when maintenance UI is presented.
    public let title: String

    /// Body copy explaining the outage or work in progress.
    public let message: String

    /// Optional link to status page or support (decoded from JSON key `supportURL`).
    public let supportURL: URL?

    /// Optional ISO-8601 datetime when maintenance is expected to end (scheduled windows).
    public let endsAt: String?

    enum CodingKeys: String, CodingKey {
        case active
        case title
        case message
        case supportURL
        case endsAt
    }

    /// Creates a maintenance payload (testing or previews).
    public init(
        active: Bool = true,
        title: String,
        message: String,
        supportURL: URL? = nil,
        endsAt: String? = nil
    ) {
        self.active = active
        self.title = title
        self.message = message
        self.supportURL = supportURL
        self.endsAt = endsAt
    }
}

/// Backward-compatible name for ``MaintenancePayload``.
public typealias MaintenanceMode = MaintenancePayload
