import Foundation
import Testing
@testable import OpsRoom

@Suite(.serialized)
struct ConfigAPIClientTests {
@Test @MainActor func fetchConfigBuildsRequest() async throws {
    try await SDKTestIsolation.shared.run {
    let session = makeMockSession()
    OpsRoom.resetLaunchCheckStateForTesting()
    OpsRoom.configure(
        apiKey: "secret-key",
        environment: .testFlight,
        options: .init(
            checkOnLaunch: false,
            apiBaseURL: URL(string: "https://api.example.com")!,
            bundleIdentifier: "com.test.app"
        )
    )

    MockURLProtocol.requestHandler = { request in
        #expect(request.url?.host == "api.example.com")
        #expect(request.url?.path == "/v1/app/config")
        #expect(request.url?.query?.contains("bundleId=com.test.app") == true)
        #expect(request.url?.query?.contains("environment=testflight") == true)
        #expect(request.value(forHTTPHeaderField: "X-API-Key") == "secret-key")

        let body = """
        {"upgrade":{"action":"none","force":null,"soft":null},"maintenance":null}
        """
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, Data(body.utf8))
    }

    let client = ConfigAPIClient(session: session)
    defer { MockURLProtocol.requestHandler = nil }

    let config = try await client.fetchConfig()
    #expect(config.upgrade.action == .none)
    }
}

private func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
}

