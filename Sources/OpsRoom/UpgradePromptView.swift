import SwiftUI

/// SwiftUI card shown for soft and force upgrade prompts (hosted in an overlay window).
struct UpgradePromptView: View {
    /// Copy and actions derived from the config API upgrade payload.
    let presentation: UpgradePromptPresentation

    /// Primary button handler (typically opens ``UpgradePromptPresentation/appStoreURL``).
    let onPrimary: () -> Void

    /// Secondary handler for soft updates (`nil` for force updates).
    let onSecondary: (() -> Void)?

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.down.app.fill")
                        .font(.title2)
                        .foregroundStyle(Color(red: 0.49, green: 0.23, blue: 0.93))
                    Text("App Update")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text(presentation.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Text(presentation.message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)

                VStack(spacing: 10) {
                    Button(action: onPrimary) {
                        Text(presentation.primaryLabel)
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(UpgradePrimaryButtonStyle())

                    if presentation.style == .soft, let secondaryLabel = presentation.secondaryLabel {
                        Button(action: { onSecondary?() }) {
                            Text(secondaryLabel)
                                .font(.body.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(UpgradeSecondaryButtonStyle())
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.15), radius: 24, y: 8)
            }
            .padding(.horizontal, 28)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }
}

private struct UpgradePrimaryButtonStyle: ButtonStyle {
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

private struct UpgradeSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: SwiftUI.ButtonStyle.Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                    .opacity(configuration.isPressed ? 0.7 : 1)
            )
    }
}
