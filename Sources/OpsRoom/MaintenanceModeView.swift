import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Full-screen maintenance UI (non-dismissable; blocks the app until server turns maintenance off).
struct MaintenanceModeView: View {
    let maintenance: MaintenancePayload
    let onSupport: (() -> Void)?

    var body: some View {
        ZStack {
            screenBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color(red: 0.49, green: 0.23, blue: 0.93))
                    .accessibilityHidden(true)

                Text(maintenance.title)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                Text(maintenance.message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)

                if let expectedBack = expectedBackText {
                    Text(expectedBack)
                        .font(.subheadline.weight(.medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .accessibilityLabel(expectedBack)
                }

                if maintenance.supportURL != nil, onSupport != nil {
                    Button(action: { onSupport?() }) {
                        Text("Status & support")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(MaintenancePrimaryButtonStyle())
                    .padding(.top, 8)
                }
            }
            .padding(32)
            .frame(maxWidth: 400)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private var expectedBackText: String? {
        guard let endsAt = maintenance.endsAt,
              let date = Self.parseISO8601(endsAt)
        else {
            return nil
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let relative = formatter.localizedString(for: date, relativeTo: Date())
        return "Expected back \(relative)"
    }

    private static func parseISO8601(_ value: String) -> Date? {
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFractional.date(from: value) {
            return date
        }
        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        return standard.date(from: value)
    }

    private var screenBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemBackground)
        #else
        Color.white
        #endif
    }
}

private struct MaintenancePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: SwiftUI.ButtonStyle.Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.49, green: 0.23, blue: 0.93))
                    .opacity(configuration.isPressed ? 0.85 : 1)
            )
    }
}
