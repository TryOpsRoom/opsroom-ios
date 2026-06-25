import SwiftUI

/// Dismissable bottom-sheet style micro survey UI.
struct SurveySheetView: View {
    let survey: MicroSurvey
    let onSubmit: (SurveyResponseValue) -> Void
    let onDismiss: () -> Void

    @State private var selectedNPS: Int?
    @State private var selectedCSAT: Int?
    @State private var selectedOptionIndex: Int?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(survey.question)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Dismiss survey")
                }

                surveyInput

                if let submitValue = pendingSubmitValue {
                    Button("Submit") {
                        onSubmit(submitValue)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Submit survey response")
                }
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

    @ViewBuilder
    private var surveyInput: some View {
        switch survey.type {
        case .nps:
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                ForEach(0 ... 10, id: \.self) { score in
                    Button {
                        selectedNPS = score
                    } label: {
                        Text("\(score)")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedNPS == score ? Color.accentColor : Color.secondary.opacity(0.12))
                            )
                            .foregroundStyle(selectedNPS == score ? Color.white : Color.primary)
                    }
                    .accessibilityLabel("Score \(score)")
                }
            }
        case .csat:
            HStack(spacing: 8) {
                ForEach(1 ... 5, id: \.self) { star in
                    Button {
                        selectedCSAT = star
                    } label: {
                        Image(systemName: (selectedCSAT ?? 0) >= star ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundStyle(.yellow)
                    }
                    .accessibilityLabel("\(star) stars")
                }
            }
        case .multiple_choice:
            VStack(spacing: 8) {
                ForEach(Array((survey.options ?? []).enumerated()), id: \.offset) { index, option in
                    Button {
                        selectedOptionIndex = index
                    } label: {
                        Text(option)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedOptionIndex == index ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
                            )
                    }
                    .accessibilityLabel(option)
                }
            }
        }
    }

    private var pendingSubmitValue: SurveyResponseValue? {
        switch survey.type {
        case .nps:
            guard let selectedNPS else { return nil }
            return .int(selectedNPS)
        case .csat:
            guard let selectedCSAT else { return nil }
            return .int(selectedCSAT)
        case .multiple_choice:
            guard let selectedOptionIndex else { return nil }
            return .int(selectedOptionIndex)
        }
    }
}

#if DEBUG
#Preview {
    SurveySheetView(
        survey: MicroSurvey(
            id: "survey_preview",
            type: .nps,
            question: "How likely are you to recommend us?",
            options: nil,
            minSessions: 0,
            minDaysSinceInstall: 0,
            minDaysBetweenSurveys: 1,
            minimumAppVersion: nil,
            trackEventName: nil,
            trackEventCount: 1
        ),
        onSubmit: { _ in },
        onDismiss: {}
    )
}
#endif
