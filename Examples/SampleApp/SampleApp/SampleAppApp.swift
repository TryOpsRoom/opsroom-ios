import OpsRoom
import SwiftUI

@main
struct SampleAppApp: App {
    init() {
        // #if DEBUG
        // let apiBaseURL = URL(string: "http://127.0.0.1:3001")!
        // #else
        let apiBaseURL = URL(string: "https://df6tl2e352.execute-api.us-east-1.amazonaws.com")!
        // #endif

        OpsRoom.configure(
            apiKey: "dev",
            environment: .production,
            options: .init(
                checkOnLaunch: true,
                apiBaseURL: apiBaseURL,
                bundleIdentifier: "com.opsroom.sample"
            )
        )
        // Environment can be changed at runtime from ContentView (no rebuild).
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
