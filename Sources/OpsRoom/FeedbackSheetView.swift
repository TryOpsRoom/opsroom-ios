import SwiftUI

/// Dismissable bottom-sheet style in-app feedback UI.
struct FeedbackSheetView: View {
    let feedback: FeedbackPayload
    let onSubmit: (String) -> Void
    let onDismiss: () -> Void

    @State private var message = ""

    private var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        !trimmedMessage.isEmpty
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(feedback.title)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Dismiss feedback")
                }

                Text(feedback.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField(feedback.placeholder, text: $message, axis: .vertical)
                    .lineLimit(3 ... 8)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(feedback.placeholder)

                Button(feedback.submitLabel) {
                    onSubmit(trimmedMessage)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!canSubmit)
                .accessibilityLabel(feedback.submitLabel)
            }
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.12), radius: 16, y: -4)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }
}

#if DEBUG
#Preview {
    FeedbackSheetView(
        feedback: FeedbackPayload(
            title: "Send feedback",
            message: "Tell us what you think.",
            placeholder: "Your feedback…",
            submitLabel: "Send"
        ),
        onSubmit: { _ in },
        onDismiss: {}
    )
}
#endif
