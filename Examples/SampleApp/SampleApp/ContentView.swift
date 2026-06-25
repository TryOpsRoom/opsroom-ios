import OpsRoom
import SwiftUI

struct ContentView: View {
    @State private var environment: AppEnvironment = .production

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("App") {
                    LabeledContent("Bundle ID", value: "com.opsroom.sample")
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("API", value: "df6tl2e352.execute-api.us-east-1.amazonaws.com")
                }

                Section("SDK environment") {
                    Picker("Environment", selection: $environment) {
                        Text("Debug").tag(AppEnvironment.debug)
                        Text("TestFlight").tag(AppEnvironment.testFlight)
                        Text("Production").tag(AppEnvironment.production)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: environment) { newValue in
                        OpsRoom.setEnvironment(newValue)
                    }

                    Text(environmentHint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Expected prompts (default policy)") {
                    Text("Production: v1.0.0 → force (minimum 2.0.0)")
                    Text("Debug / TestFlight: disabled → no prompt")
                    Text("Bump version in Xcode to 1.9.0 → soft on production")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                Section("Rating prompt") {
                    Text(
                        "Enable in dashboard → Rating prompts, then tap below after config loads."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    Button("Request review if appropriate") {
                        Task {
                            await OpsRoom.requestReviewIfAppropriate()
                        }
                    }
                }

                Section("Announcements") {
                    Text(
                        "Shown once per announcement ID. Change the ID in the dashboard or reset below to test again."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    #if DEBUG
                    Button("Reset announcements shown state") {
                        UserDefaults.standard.removeObject(
                            forKey: "opsroom.shownAnnouncementIds"
                        )
                    }
                    #endif
                }

                Section("Micro surveys") {
                    Text(
                        "Published on AWS demo app (survey_sample). Tap Check for updates — or reset state below if you dismissed recently."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    Button("Track event: completed_export") {
                        OpsRoom.trackEvent("completed_export")
                    }
                    #if DEBUG
                    Button("Reset survey shown state") {
                        let prefix = "opsroom.microSurvey"
                        for key in [
                            "\(prefix).lastShownSurveyId",
                            "\(prefix).lastShownDate",
                            "\(prefix).trackEventCounts",
                            "\(prefix).sessionCount",
                        ] {
                            UserDefaults.standard.removeObject(forKey: key)
                        }
                    }
                    #endif
                }

                Section("Release notes") {
                    Text(
                        "Dashboard version must match the app version (currently \(appVersion)). Shown once per version."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    #if DEBUG
                    Button("Reset release-notes shown state") {
                        UserDefaults.standard.removeObject(
                            forKey: "opsroom.shownReleaseNoteVersions"
                        )
                    }
                    #endif
                }

                Section {
                    Button("Check for updates") {
                        Task {
                            await OpsRoom.checkForUpdates()
                        }
                    }
                }
            }
            .navigationTitle("OpsRoom Sample")
        }
    }

    private var environmentHint: String {
        switch environment {
        case .production:
            return "Production checks are enabled in the seeded API policy."
        case .debug, .testFlight:
            return "Switch to Production to see force/soft prompts with the demo policy."
        }
    }
}

#Preview {
    ContentView()
}
