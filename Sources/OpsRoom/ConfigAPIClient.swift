import Foundation

/// Errors thrown while fetching or decoding remote config (internal; not surfaced to app UI).
enum ConfigAPIError: Error, Equatable {
    /// ``OpsRoom/configure(apiKey:environment:options:)`` was not called.
    case notConfigured

    /// No bundle ID from options or `Bundle.main`.
    case missingBundleIdentifier

    /// Query items could not be encoded into a URL.
    case invalidURL

    /// Response was not HTTP or body could not be decoded.
    case invalidResponse

    /// Non-success HTTP status from the config API.
    case httpStatus(Int)
}

/// Abstraction over config HTTP fetch (production client or test doubles).
protocol ConfigAPIClientProtocol: Sendable {
    /// Fetches and decodes `GET /v1/app/config` using current ``Configuration`` snapshot.
    func fetchConfig() async throws -> AppConfigResponse
}

/// Default client that calls the OpsRoom config API with `URLSession`.
struct ConfigAPIClient: ConfigAPIClientProtocol {
    private let session: URLSession
    private let timeout: TimeInterval

    /// - Parameters:
    ///   - session: Session used for the config request (inject `URLProtocol` in tests).
    ///   - timeout: Request timeout in seconds. Default `10`.
    init(session: URLSession = .shared, timeout: TimeInterval = 10) {
        self.session = session
        self.timeout = timeout
    }

    func fetchConfig() async throws -> AppConfigResponse {
        let configuration = Configuration.shared.snapshot()
        guard configuration.isConfigured else {
            throw ConfigAPIError.notConfigured
        }

        let bundleId = configuration.bundleIdentifier ?? AppInfo.bundleIdentifier
        guard let bundleId else {
            throw ConfigAPIError.missingBundleIdentifier
        }

        let url = try ConfigAPIRequestBuilder.buildConfigURL(
            apiBaseURL: configuration.apiBaseURL,
            bundleId: bundleId,
            appVersion: AppInfo.appVersion,
            osVersion: AppInfo.osVersion,
            sdkVersion: OpsRoomSDKVersion.current,
            environment: configuration.environment,
            locale: AppInfo.preferredLocale
        )

        let request = ConfigAPIRequestBuilder.buildRequest(
            url: url,
            apiKey: configuration.apiKey,
            timeout: timeout
        )

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ConfigAPIError.invalidResponse
        }
        guard (200 ... 299).contains(http.statusCode) else {
            throw ConfigAPIError.httpStatus(http.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(AppConfigResponse.self, from: data)
    }
}
