import Foundation

/// Reads device and bundle metadata included on config API requests.
enum AppInfo {
    /// `Bundle.main.bundleIdentifier`, if set.
    static var bundleIdentifier: String? {
        Bundle.main.bundleIdentifier
    }

    /// `CFBundleShortVersionString`, or `"0.0.0"` when missing.
    static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return version?.isEmpty == false ? version! : "0.0.0"
    }

    /// OS version string sent as the `osVersion` query parameter.
    static var osVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    /// First entry from `Locale.preferredLanguages`, sent as optional `locale` query param.
    static var preferredLocale: String? {
        Locale.preferredLanguages.first
    }
}
