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
        VStack(alignment: .leading, spacing: 12) {
            Text(subtitle.uppercased())
                .font(.caption)
                .foregroundColor(Theme.muted)
                .tracking(1.2)
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundColor(Theme.ink)
            HStack(spacing: 12) {
                wordButton(label: wordA.capitalized, action: onTapWordA)
                Text("vs")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.muted)
                wordButton(label: wordB.capitalized, action: onTapWordB)
            }
            Text("Tap a word for its definition.")
                .font(.footnote)
                .foregroundColor(Theme.muted)
        }
        .cardStyle()
    }

    @ViewBuilder
    private func wordButton(label: String, action: (() -> Void)?) -> some View {
        if let action {
            Button(action: action) {
                Text(label)
                    .font(.system(size: 32, weight: .semibold, design: .serif))
                    .foregroundColor(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .buttonStyle(.plain)
        } else {
            Text(label)
                .font(.system(size: 32, weight: .semibold, design: .serif))
                .foregroundColor(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}
