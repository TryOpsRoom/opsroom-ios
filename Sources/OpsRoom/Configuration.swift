import Foundation

/// Options passed to ``OpsRoom/configure(apiKey:environment:options:)``.
///
/// Use this type to point the SDK at a custom API host (local dev or your deployed stack),
/// override the bundle ID sent to the server, and control automatic upgrade checks on cold launch.
public struct ConfigurationOptions: Sendable {
    /// When `true`, ``OpsRoom/checkForUpdates()`` runs once per process immediately after configure.
    ///
    /// Default is `true`. Set to `false` if you only want manual checks (for example after login).
    public var checkOnLaunch: Bool

    /// API origin **without** a trailing slash. The SDK appends `/v1/app/config`.
    ///
    /// Default is `https://api.tryopsroom.com`. For local development use something like
    /// `http://127.0.0.1:3001` and ensure App Transport Security allows cleartext if needed.
    public var apiBaseURL: URL

    /// Bundle identifier sent as the `bundleId` query parameter.
    ///
    /// When `nil`, uses `Bundle.main.bundleIdentifier`. Set explicitly for extensions, tests,
    /// or when the main bundle ID does not match the API key registered in OpsRoom.
    public var bundleIdentifier: String?

    /// When `true`, the last successful config response is stored on device for offline use.
    ///
    /// Default is `true`. Cached data never triggers a **force** update (soft at most). See ``configCacheTTL``.
    public var enableConfigCache: Bool

    /// How long a cached config response remains eligible for offline soft/maintenance UI.
    ///
    /// Default is 3600 seconds (1 hour). After TTL expires, offline launches fail open with no prompts.
    public var configCacheTTL: TimeInterval

    /// When `true`, re-fetches config whenever the app enters the foreground (in addition to cold launch).
    ///
    /// Default is `true`. Lets maintenance mode clear soon after you turn it off in the dashboard.
    public var checkOnForeground: Bool

    /// Creates configuration options for the SDK.
    ///
    /// - Parameters:
    ///   - checkOnLaunch: Whether to run one automatic upgrade check after configure. Default `true`.
    ///   - apiBaseURL: Config API host without trailing slash. Default production host.
    ///   - bundleIdentifier: Optional override for `bundleId`; `nil` uses the main bundle.
    ///   - enableConfigCache: Persist last successful config for offline degradation. Default `true`.
    ///   - configCacheTTL: Cache lifetime in seconds. Default `3600`.
    ///   - checkOnForeground: Refetch on app foreground. Default `true`.
    public init(
        checkOnLaunch: Bool = true,
        apiBaseURL: URL = URL(string: "https://api.tryopsroom.com")!,
        bundleIdentifier: String? = nil,
        enableConfigCache: Bool = true,
        configCacheTTL: TimeInterval = 3600,
        checkOnForeground: Bool = true
    ) {
        self.checkOnLaunch = checkOnLaunch
        self.apiBaseURL = apiBaseURL
        self.bundleIdentifier = bundleIdentifier
        self.enableConfigCache = enableConfigCache
        self.configCacheTTL = configCacheTTL
        self.checkOnForeground = checkOnForeground
    }
}

/// Immutable snapshot of SDK configuration used when building config API requests.
struct ConfigurationSnapshot: Sendable {
    let apiKey: String
    let environment: AppEnvironment
    let apiBaseURL: URL
    let bundleIdentifier: String?
    let enableConfigCache: Bool
    let configCacheTTL: TimeInterval
    let checkOnForeground: Bool
    let isConfigured: Bool
}

/// Thread-safe holder for SDK configuration set by ``OpsRoom/configure(apiKey:environment:options:)``.
final class Configuration: @unchecked Sendable {
    static let shared = Configuration()

    private let lock = NSLock()
    private var apiKey: String = ""
    private var environment: AppEnvironment = .production
    private var options: ConfigurationOptions = .init()
    private var apiBaseURL: URL = ConfigurationOptions().apiBaseURL
    private var bundleIdentifier: String?

    /// `true` after a non-empty API key has been applied via configure.
    var isConfigured: Bool {
        snapshot().isConfigured
    }

    private init() {}

    func apply(
        apiKey: String,
        environment: AppEnvironment,
        options: ConfigurationOptions
    ) {
        lock.lock()
        defer { lock.unlock() }
        self.apiKey = apiKey
        self.environment = environment
        self.options = options
        self.apiBaseURL = options.apiBaseURL
        self.bundleIdentifier = options.bundleIdentifier
    }

    func snapshot() -> ConfigurationSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return ConfigurationSnapshot(
            apiKey: apiKey,
            environment: environment,
            apiBaseURL: apiBaseURL,
            bundleIdentifier: bundleIdentifier,
            enableConfigCache: options.enableConfigCache,
            configCacheTTL: options.configCacheTTL,
            checkOnForeground: options.checkOnForeground,
            isConfigured: !apiKey.isEmpty
        )
    }

    func setEnvironment(_ newEnvironment: AppEnvironment) {
        lock.lock()
        defer { lock.unlock() }
        environment = newEnvironment
    }

    #if DEBUG
    /// Clears all stored configuration (test targets only).
    func resetForTesting() {
        lock.lock()
        defer { lock.unlock() }
        apiKey = ""
        environment = .production
        options = .init()
        apiBaseURL = ConfigurationOptions().apiBaseURL
        bundleIdentifier = nil
    }
    #endif
}
