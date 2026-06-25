import Foundation

/// Persisted config API payload plus save time (UserDefaults, scoped per app install).
struct CachedAppConfig: Codable, Sendable, Equatable {
    let savedAt: Date
    let response: AppConfigResponse
}

enum ConfigCacheStore {
    private static let keyPrefix = "com.opsroom.sdk.configCache"

    #if DEBUG
    /// Override for unit tests (`UserDefaults(suiteName:)`).
    nonisolated(unsafe) static var defaultsOverride: UserDefaults?
    #endif

    private static var defaults: UserDefaults {
        #if DEBUG
        if let defaultsOverride {
            return defaultsOverride
        }
        #endif
        return .standard
    }

    static func storageKey(bundleIdentifier: String) -> String {
        "\(keyPrefix).\(bundleIdentifier)"
    }

    static func save(_ response: AppConfigResponse, bundleIdentifier: String) {
        let entry = CachedAppConfig(savedAt: Date(), response: response)
        guard let data = try? JSONEncoder().encode(entry) else {
            return
        }
        defaults.set(data, forKey: storageKey(bundleIdentifier: bundleIdentifier))
    }

    static func load(bundleIdentifier: String) -> CachedAppConfig? {
        guard let data = defaults.data(forKey: storageKey(bundleIdentifier: bundleIdentifier)),
              let entry = try? JSONDecoder().decode(CachedAppConfig.self, from: data)
        else {
            return nil
        }
        return entry
    }

    static func isValid(entry: CachedAppConfig, ttl: TimeInterval) -> Bool {
        guard ttl > 0 else {
            return false
        }
        return Date().timeIntervalSince(entry.savedAt) <= ttl
    }

    #if DEBUG
    static func clear(bundleIdentifier: String) {
        defaults.removeObject(forKey: storageKey(bundleIdentifier: bundleIdentifier))
    }

    static func clearAllForTesting() {
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(keyPrefix) {
            defaults.removeObject(forKey: key)
        }
    }
    #endif
}
