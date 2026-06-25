import Foundation
import Testing
@testable import OpsRoom

@Suite struct ConfigAPIRequestBuilderTests {
    @Test func buildConfigURLIncludesQueryItems() throws {
        let url = try ConfigAPIRequestBuilder.buildConfigURL(
            apiBaseURL: URL(string: "https://api.example.com")!,
            bundleId: "com.test.app",
            appVersion: "1.2.3",
            osVersion: "17.0",
            sdkVersion: "0.1.0",
            environment: .testFlight,
            locale: "en-US"
        )

        #expect(url.host == "api.example.com")
        #expect(url.path == "/v1/app/config")
        let query = url.query ?? ""
        #expect(query.contains("bundleId=com.test.app"))
        #expect(query.contains("appVersion=1.2.3"))
        #expect(query.contains("environment=testflight"))
        #expect(query.contains("locale=en-US"))
    }

    @Test func buildRequestSetsAPIKeyHeader() {
        let url = URL(string: "https://api.example.com/v1/app/config")!
        let request = ConfigAPIRequestBuilder.buildRequest(
            url: url,
            apiKey: "secret",
            timeout: 15
        )
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "X-API-Key") == "secret")
        #expect(request.timeoutInterval == 15)
    }
}
