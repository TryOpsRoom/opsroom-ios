import SwiftUI

/// Per-version what's-new UI with basic Markdown rendering.
struct ReleaseNotesView: View {
    let releaseNotes: ReleaseNotes
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("What's New")
                        .font(.title2.weight(.semibold))
                    Text("Version \(releaseNotes.version)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ViewThatFits(in: .vertical) {
                    releaseNotesBody
                    ScrollView {
                        releaseNotesBody
                    }
                    .frame(maxHeight: 280)
                }

                Button("Continue", action: onDismiss)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
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

    private var releaseNotesBody: some View {
        Text(.init(releaseNotes.content))
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#if DEBUG
#Preview {
    ReleaseNotesView(
        releaseNotes: ReleaseNotes(
            version: "2.1.0",
            content: "## What's New\n- Dark mode\n- Bug fixes",
            style: .sheet
        ),
        onDismiss: {}
    )
}
#endif
