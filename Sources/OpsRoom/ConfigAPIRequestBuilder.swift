import Foundation

/// Builds URLs and requests for `GET /v1/app/config`.
enum ConfigAPIRequestBuilder {
    /// Constructs the config endpoint URL with required query parameters.
    ///
    /// - Parameters:
    ///   - apiBaseURL: Origin without trailing slash.
    ///   - bundleId: App bundle identifier registered with the API key.
    ///   - appVersion: `CFBundleShortVersionString` or override.
    ///   - osVersion: Device OS version string.
    ///   - sdkVersion: ``OpsRoomSDKVersion/current``.
    ///   - environment: Build channel (``AppEnvironment/rawValue``).
    ///   - locale: Optional `locale` query item (e.g. `en-US`).
    /// - Throws: ``ConfigAPIError/invalidURL`` if components fail to resolve.
    static func buildConfigURL(
        apiBaseURL: URL,
        bundleId: String,
        appVersion: String,
        osVersion: String,
        sdkVersion: String,
        environment: AppEnvironment,
        locale: String?
    ) throws -> URL {
        var components = URLComponents(
            url: apiBaseURL.appendingPathComponent("v1/app/config"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "bundleId", value: bundleId),
            URLQueryItem(name: "appVersion", value: appVersion),
            URLQueryItem(name: "osVersion", value: osVersion),
            URLQueryItem(name: "sdkVersion", value: sdkVersion),
            URLQueryItem(name: "environment", value: environment.rawValue),
        ]
        if let locale {
            components?.queryItems?.append(URLQueryItem(name: "locale", value: locale))
        }
        guard let url = components?.url else {
            throw ConfigAPIError.invalidURL
        }
        return url
    }

    /// Creates an authenticated GET request for the config URL.
    ///
    /// - Parameters:
    ///   - url: Full config URL from ``buildConfigURL(apiBaseURL:bundleId:appVersion:osVersion:sdkVersion:environment:locale:)``.
    ///   - apiKey: Value for the `X-API-Key` header.
    ///   - timeout: `URLRequest.timeoutInterval`.
    static func buildRequest(
        url: URL,
        apiKey: String,
        timeout: TimeInterval
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeout
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        return request
    }
}
