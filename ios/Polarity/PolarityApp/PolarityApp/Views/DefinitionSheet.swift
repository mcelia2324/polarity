import SwiftUI

/// A clean, scrollable sheet showing a word and its reflective definition.
/// Shared by Today, History, the history detail, and onboarding so they stay consistent.
struct DefinitionSheet: View {
    let word: String
    let definition: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(word.capitalized)
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundColor(Theme.accentDark)

                Rectangle()
                    .fill(Theme.muted.opacity(0.18))
                    .frame(width: 32, height: 2)

                Text(definition)
                    .font(.system(size: 17))
                    .foregroundColor(Theme.ink)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.card)
    }
}
