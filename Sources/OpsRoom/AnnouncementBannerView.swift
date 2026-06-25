import SwiftUI

/// Top-of-screen announcement banner; hosted in a top-aligned overlay (see ``AnnouncementBannerOverlayController``).
struct AnnouncementBannerView: View {
    let announcement: Announcement
    let onDismiss: () -> Void
    let onCTA: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(announcement.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(announcement.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                if announcement.ctaLabel != nil, let onCTA {
                    Text(announcement.ctaLabel ?? "Continue")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onCTA)
                        .accessibilityAddTraits(.isButton)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
        .accessibilityElement(children: .contain)
    }
}

#if DEBUG
#Preview {
    AnnouncementBannerView(
        announcement: Announcement(
            id: "ann_banner",
            title: "Dark mode is here",
            message: "Head to Settings to try it.",
            style: .banner,
            ctaLabel: "Open Settings",
            ctaURL: URL(string: "https://example.com")
        ),
        onDismiss: {},
        onCTA: {}
    )
}
#endif
