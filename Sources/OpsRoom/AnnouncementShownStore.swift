import Foundation

/// Tracks which announcement IDs have already been presented on this device.
public struct AnnouncementShownStore {
    private let defaults: UserDefaults
    private let storageKey: String

    public init(
        defaults: UserDefaults = .standard,
        storageKey: String = "opsroom.shownAnnouncementIds"
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    public func hasShown(id: String) -> Bool {
        shownIds().contains(id)
    }

    public func markShown(id: String) {
        var ids = shownIds()
        ids.insert(id)
        defaults.set(Array(ids), forKey: storageKey)
    }

    public func shouldPresent(_ announcement: Announcement) -> Bool {
        !hasShown(id: announcement.id)
    }

    private func shownIds() -> Set<String> {
        let raw = defaults.stringArray(forKey: storageKey) ?? []
        return Set(raw)
    }

    #if DEBUG
    public func resetForTesting() {
        defaults.removeObject(forKey: storageKey)
    }
    #endif
}
