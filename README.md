# OpsRoom iOS SDK

Swift Package for iOS 16+. Ships remote config for forced upgrades, maintenance mode, announcements, release notes, rating prompts, and micro surveys.

- **Dashboard:** [tryopsroom.com](https://www.tryopsroom.com)
- **Sample app:** [`Examples/SampleApp`](Examples/SampleApp)

## Installation

### Swift Package Manager (recommended)

In Xcode: **File → Add Package Dependencies** →  
`https://github.com/TryOpsRoom/opsroom-ios`

Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/TryOpsRoom/opsroom-ios", from: "0.1.0"),
],
targets: [
    .target(name: "MyApp", dependencies: ["OpsRoom"]),
]
```

### Local path

```swift
.package(path: "../opsroom-ios")
```

## Quick start

```swift
import OpsRoom
import SwiftUI

@main
struct MyApp: App {
    init() {
        OpsRoom.configure(
            apiKey: "YOUR_API_KEY",
            environment: .production,
            options: .init(
                checkOnLaunch: true,
                apiBaseURL: URL(string: "https://YOUR_API_HOST")!,
                bundleIdentifier: nil // uses Bundle.main by default
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

Create apps and API keys in the [OpsRoom dashboard](https://www.tryopsroom.com/apps).

## API surface

Public API symbols are documented with DocC-style `///` comments in `Sources/OpsRoom/` (open the package in Xcode and use **Product → Build Documentation**, or Option-click any symbol).

| Symbol | Role |
|--------|------|
| ``OpsRoom`` | Configure SDK, change environment, trigger upgrade checks |
| ``ConfigurationOptions`` | API base URL, bundle override, `checkOnLaunch` |
| ``AppEnvironment`` | `debug` / `testflight` / `production` channel sent to the API |
| ``MaintenanceMode`` | Decoded maintenance payload |
| ``Announcement`` | One-time in-app message from config API |
| ``ReleaseNotes`` | Per-version What's New from config API |
| ``RatingPrompt`` | Remote rules for in-app review eligibility |
| ``MicroSurvey`` | NPS, CSAT, or multiple-choice survey from config API |
| ``OpsRoomSDKVersion`` | SDK version string sent as `sdkVersion` |

## Sample app

```bash
brew install xcodegen   # if needed
cd Examples/SampleApp
xcodegen generate
open SampleApp.xcodeproj
```

See [Examples/SampleApp/README.md](Examples/SampleApp/README.md) for local API setup and manual QA flows.

## Development

```bash
swift build && swift test
```

## Behavior summary

- **Cold launch:** When `checkOnLaunch` is true (default), the SDK fetches config once per process after `configure`.
- **Offline / errors:** Recent cached config (default TTL **1 hour**) may show **soft** update or **maintenance**. **Force** updates are never shown from cache alone.
- **Maintenance:** Full-screen blocking UI when `maintenance.active` is true.
- **Announcements / release notes / surveys:** Shown once per id or version per device, after higher-priority flows.
- **Requirements:** iOS 16+, network access to your OpsRoom API, valid API key scoped to your bundle ID.

## License

MIT — see [LICENSE](LICENSE).
