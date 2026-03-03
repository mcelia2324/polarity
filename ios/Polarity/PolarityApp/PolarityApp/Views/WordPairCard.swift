import SwiftUI

struct WordPairCard: View {
    let title: String
    let subtitle: String
    let wordA: String
    let wordB: String
    let onTapWordA: (() -> Void)?
    let onTapWordB: (() -> Void)?

    @State private var wordsVisible = false

    init(
        title: String,
        subtitle: String,
        wordA: String,
        wordB: String,
        onTapWordA: (() -> Void)? = nil,
        onTapWordB: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.wordA = wordA
        self.wordB = wordB
        self.onTapWordA = onTapWordA
        self.onTapWordB = onTapWordB
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(subtitle.uppercased())
                .font(.caption)
                .foregroundColor(Theme.muted)
                .tracking(1.4)

            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundColor(Theme.ink)

            HStack(spacing: 14) {
                wordButton(label: wordA.capitalized, action: onTapWordA)
                    .scaleEffect(wordsVisible ? 1 : 0.7)
                    .opacity(wordsVisible ? 1 : 0)

                Text("vs")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.muted)
                    .opacity(wordsVisible ? 1 : 0)

                wordButton(label: wordB.capitalized, action: onTapWordB)
                    .scaleEffect(wordsVisible ? 1 : 0.7)
                    .opacity(wordsVisible ? 1 : 0)
            }

            Text("Tap a word for its definition.")
                .font(.caption)
                .foregroundColor(Theme.muted.opacity(0.8))
                .opacity(wordsVisible ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.15)) {
                wordsVisible = true
            }
        }
    }

    @ViewBuilder
    private func wordButton(label: String, action: (() -> Void)?) -> some View {
        if let action {
            Button(action: action) {
                Text(label)
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                    .foregroundColor(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .buttonStyle(.plain)
        } else {
            Text(label)
                .font(.system(size: 30, weight: .semibold, design: .serif))
                .foregroundColor(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}
