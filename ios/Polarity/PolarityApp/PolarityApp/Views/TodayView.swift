import SwiftUI

struct TodayView: View {
    @State private var wordPair: WordPair?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showJournal = false
    @State private var selectedDefinition: DefinitionSheetItem?

    @ObservedObject var journalStore: JournalStore

    private var streak: Int { journalStore.currentStreak }

    var body: some View {
        NavigationStack {
            Group {
                if let pair = wordPair {
                    content(pair)
                } else if isLoading {
                    loadingView
                } else {
                    errorView
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if streak > 0 {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.footnote)
                            Text("\(streak)")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(Theme.accent)
                        .accessibilityLabel("\(streak) day streak")
                    }
                }
            }
        }
        .task { await load() }
        .sheet(isPresented: $showJournal) {
            if let pair = wordPair {
                JournalEditorView(
                    journalStore: journalStore,
                    date: Date(),
                    wordA: pair.wordA,
                    wordB: pair.wordB,
                    note: journalStore.entry(for: Date())?.note ?? ""
                )
            }
        }
        .sheet(item: $selectedDefinition) { item in
            DefinitionSheet(word: item.word, definition: item.definition)
        }
    }

    // MARK: - Content
    //
    // The whole stack is offered at decreasing scales and SwiftUI renders the largest one
    // that fits, so the screen never scrolls on any device. Each card hugs its own content
    // (the contemplation box is never stretched), and the chosen stack is centered.

    private func content(_ pair: WordPair) -> some View {
        ViewThatFits(in: .vertical) {
            stack(pair, textSize: 18, lineSpacing: 7)
            stack(pair, textSize: 16.5, lineSpacing: 6)
            stack(pair, textSize: 15, lineSpacing: 5)
            stack(pair, textSize: 13.5, lineSpacing: 4)
            stack(pair, textSize: 12, lineSpacing: 3)
            stack(pair, textSize: 11, lineSpacing: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .readableWidth()
    }

    private func stack(_ pair: WordPair, textSize: CGFloat, lineSpacing: CGFloat) -> some View {
        VStack(spacing: 16) {
            WordPairCard(
                title: "",
                subtitle: formattedDate(pair.date),
                wordA: pair.wordA,
                wordB: pair.wordB,
                onTapWordA: {
                    selectedDefinition = DefinitionSheetItem(
                        word: pair.wordA,
                        definition: pair.wordADefinition ?? "Definition unavailable."
                    )
                },
                onTapWordB: {
                    selectedDefinition = DefinitionSheetItem(
                        word: pair.wordB,
                        definition: pair.wordBDefinition ?? "Definition unavailable."
                    )
                },
                compact: true
            )
            .gentleAppear(0)

            if let contemplation = pair.contemplation, !contemplation.isEmpty {
                contemplationCard(contemplation, textSize: textSize, lineSpacing: lineSpacing)
                    .gentleAppear(0.08)
            }

            if let quote = pair.quote {
                quoteView(quote, author: pair.quoteAuthor)
                    .gentleAppear(0.16)
            }

            journalButton
                .gentleAppear(0.22)
        }
    }

    private func contemplationCard(_ text: String, textSize: CGFloat, lineSpacing: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: "leaf.fill")
                    .font(.caption2)
                Text("TODAY'S CONTEMPLATION")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.6)
            }
            .foregroundColor(Theme.accentDark)

            Text(text)
                .font(.system(size: textSize, weight: .regular, design: .serif))
                .foregroundColor(Theme.ink.opacity(0.9))
                .lineSpacing(lineSpacing)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [Theme.card, Theme.accent.opacity(0.07)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Theme.accent.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: Theme.cardShadow, radius: 20, x: 0, y: 10)
    }

    private func quoteView(_ quote: String, author: String?) -> some View {
        VStack(spacing: 7) {
            Rectangle()
                .fill(Theme.muted.opacity(0.2))
                .frame(width: 36, height: 1)
                .padding(.bottom, 2)

            Text("\u{201C}\(quote)\u{201D}")
                .font(.system(size: 15, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(Theme.ink.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .minimumScaleFactor(0.7)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            if let author {
                Text(author)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(Theme.muted)
                    .tracking(0.5)
            }
        }
        .padding(.horizontal, 12)
    }

    private var journalButton: some View {
        Button {
            showJournal = true
        } label: {
            Label("Journal", systemImage: "square.and.pencil")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity)
                .background(Theme.accent)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .shadow(color: Theme.accent.opacity(0.25), radius: 10, x: 0, y: 6)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Theme.accent)
                .scaleEffect(1.5)
            Text("Loading today's polarity…")
                .font(.subheadline)
                .foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundColor(Theme.muted.opacity(0.4))
            Text(errorMessage ?? "Unable to load today's words.")
                .font(.subheadline)
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
            Button {
                Task { await load() }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Theme.accent)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }

    private func formattedDate(_ raw: String) -> String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        parser.locale = Locale(identifier: "en_US_POSIX")
        guard let date = parser.date(from: raw) else { return raw }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func load() async {
        do {
            isLoading = true
            errorMessage = nil
            let pair = try await APIClient.shared.fetchWordOfDay()
            await MainActor.run {
                self.wordPair = pair
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

private struct DefinitionSheetItem: Identifiable {
    let id = UUID()
    let word: String
    let definition: String
}
