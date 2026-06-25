import Foundation

/// Display style for per-version release notes.
public enum ReleaseNotesStyle: String, Codable, Sendable, Equatable {
    case modal
    case sheet
}

/// Server-driven release notes for the current app version.
public struct ReleaseNotes: Codable, Sendable, Equatable {
    public let version: String
    public let content: String
    public let style: ReleaseNotesStyle

    public init(version: String, content: String, style: ReleaseNotesStyle) {
        self.version = version
        self.content = content
        self.style = style
    }
}
