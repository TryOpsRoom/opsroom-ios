import Foundation

/// Display style for an in-app announcement.
public enum AnnouncementStyle: String, Codable, Sendable, Equatable {
    case modal
    case banner
}

/// Server-driven announcement returned in the config API `announcement` field.
public struct Announcement: Codable, Sendable, Equatable {
    /// Stable identifier; used to show at most once per device.
    public let id: String

    public let title: String
    public let message: String
    public let style: AnnouncementStyle

    public let ctaLabel: String?
    public let ctaURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case message
        case style
        case ctaLabel
        case ctaURL
    }

    public init(
        id: String,
        title: String,
        message: String,
        style: AnnouncementStyle,
        ctaLabel: String? = nil,
        ctaURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.style = style
        self.ctaLabel = ctaLabel
        self.ctaURL = ctaURL
    }
}
