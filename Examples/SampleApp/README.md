# OpsRoom Sample App

Dogfood app for forced upgrades, maintenance, announcements, release notes, rating prompts, and micro surveys. Bundle version is **1.0.0** so the default demo policy returns a **force** prompt on **Production**.

## Prerequisites

- Xcode 15+ with iOS 16+ simulator or a physical device
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project
- Config API reachable (local or deployed) with the **demo** app seeded

## Generate Xcode project (first time)

```bash
brew install xcodegen   # if needed
cd Examples/SampleApp
xcodegen generate
open SampleApp.xcodeproj
```

In Xcode: **File → Packages → Reset Package Caches**, then build again.

### “Missing package product 'OpsRoom'”

1. From `Examples/SampleApp`, run `xcodegen generate` (links the local package at the repo root).
2. In Xcode: **File → Packages → Reset Package Caches** → **Resolve Package Versions**.
3. Confirm `Package.swift` exists at the repository root (path is `../..` from `SampleApp.xcodeproj`).
4. If the project lives on **iCloud Drive**, ensure the repo folder is fully downloaded or clone to a local path such as `~/Developer`.

Select the **SampleApp** scheme → an **iPhone** simulator → Run (⌘R).

On first launch you should see the **force update** modal (app v1.0.0, API minimum v2.0.0).

## Local API (recommended when not deploying)

Use this when AWS deploy or Docker on another machine is unavailable, as long as you can run the API on your Mac.

### 1. Start a local config API

Run the OpsRoom config API on your Mac (Docker + local DynamoDB), then seed the demo app with API key `dev`. Point the dashboard at the same API if you want to edit policy from the UI.

### 2. Point SampleApp at localhost

In `SampleApp/SampleAppApp.swift`, set:

```swift
apiBaseURL: URL(string: "http://127.0.0.1:3001")!
```

### 3. API keys

| Key | When to use |
|-----|-------------|
| `dev` | Seeded demo key for bundle `com.opsroom.sample` |
| `or_…` | Keys created in the dashboard when you **Add app** |

```swift
OpsRoom.configure(
    apiKey: "dev",
    environment: .production,
    options: .init(
        checkOnLaunch: true,
        apiBaseURL: URL(string: "http://127.0.0.1:3001")!
    )
)
```

**Simulator note:** `127.0.0.1` is the Mac host from the iOS simulator. Use your Mac’s LAN IP on a physical device.

## Deployed dev API (optional)

Default `SampleAppApp.swift` may point at your AWS execute-api URL. You need a deployed `opsroom-dev` stack, seeded **OpsRoom-dev** table, and API key `dev` (or a dashboard key).

## Test matrix

| Goal | How |
|------|-----|
| **Environment** | In-app **Debug / TestFlight / Production** picker |
| **Soft** prompt | Production + Xcode version **1.9.0** |
| **None** | Production + version **2.1.0** or higher |
| **Announcements** | Dashboard `/apps/demo/announcements` |
| **Release notes** | `/apps/demo/release-notes`, version matches Xcode |
| **Rating prompt** | `/apps/demo/rating-prompts` |
| **Micro survey** | `/apps/demo/surveys` |

## Package dependency

The app links the Swift package at the **repository root** (`path: ../..` in `project.yml`).
