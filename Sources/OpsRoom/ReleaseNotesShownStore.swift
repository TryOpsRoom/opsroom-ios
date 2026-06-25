import Foundation

/// Tracks which app versions have already shown release notes on this device.
public struct ReleaseNotesShownStore {
    private let defaults: UserDefaults
    private let storageKey: String

    public init(
        defaults: UserDefaults = .standard,
        storageKey: String = "opsroom.shownReleaseNoteVersions"
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    public func hasShown(version: String) -> Bool {
        shownVersions().contains(version)
    }

    public func markShown(version: String) {
        var versions = shownVersions()
        versions.insert(version)
        defaults.set(Array(versions), forKey: storageKey)
    }

    public func shouldPresent(_ releaseNotes: ReleaseNotes) -> Bool {
        !hasShown(version: releaseNotes.version)
    }

    private func shownVersions() -> Set<String> {
        let raw = defaults.stringArray(forKey: storageKey) ?? []
        return Set(raw)
    }

    #if DEBUG
    public func resetForTesting() {
        defaults.removeObject(forKey: storageKey)
    }
    #endif
}
