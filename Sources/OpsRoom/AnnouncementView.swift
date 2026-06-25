import SwiftUI

/// In-app announcement modal with dimmed backdrop and card layout.
struct AnnouncementView: View {
    let announcement: Announcement
    let onDismiss: () -> Void
    let onCTA: (() -> Void)?

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(announcement.title)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text(announcement.message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                VStack(spacing: 10) {
                    if announcement.ctaLabel != nil, onCTA != nil {
                        Button(announcement.ctaLabel ?? "Continue", action: { onCTA?() })
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                    }

                    Button("Dismiss", action: onDismiss)
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                }
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

#if DEBUG
#Preview {
    AnnouncementView(
        announcement: Announcement(
            id: "ann_preview",
            title: "Dark mode is here",
            message: "Head to Settings to try it.",
            style: .modal,
            ctaLabel: "Open Settings",
            ctaURL: URL(string: "https://example.com")
        ),
        onDismiss: {},
        onCTA: {}
    )
}
#endif
