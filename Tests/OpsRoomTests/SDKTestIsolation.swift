import Foundation

/// Serializes tests that mutate global SDK singletons to avoid cross-suite races.
actor SDKTestIsolation {
    static let shared = SDKTestIsolation()

    @MainActor
    func run<T>(_ body: @MainActor () async throws -> T) async rethrows -> T {
        try await body()
    }
}
