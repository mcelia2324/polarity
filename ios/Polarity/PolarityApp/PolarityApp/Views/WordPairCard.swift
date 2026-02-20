import SwiftUI

struct WordPairCard: View {
    let title: String
    let subtitle: String
    let wordA: String
    let wordB: String
    let onTapWordA: (() -> Void)?
    let onTapWordB: (() -> Void)?

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
                Text("vs")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.muted)
                wordButton(label: wordB.capitalized, action: onTapWordB)
            }

            Text("Tap a word for its definition.")
                .font(.caption)
                .foregroundColor(Theme.muted.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
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
