import SwiftUI

struct TodayView: View {
    @State private var wordPair: WordPair?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showJournal = false
    @State private var selectedDefinition: DefinitionSheetItem?
    @State private var appeared = false

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

    // MARK: - Main content (fits on one screen, no scrolling)

    private func content(_ pair: WordPair) -> some View {
        VStack(spacing: 14) {
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

            if let contemplation = pair.contemplation, !contemplation.isEmpty {
                contemplationCard(contemplation)
            } else {
                Spacer(minLength: 0)
            }

            if let quote = pair.quote {
                quoteView(quote, author: pair.quoteAuthor)
            }

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
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .readableWidth()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
    }

    /// The contemplation fills the remaining vertical space and picks the largest font
    /// that fits, so the whole screen never needs to scroll on any device.
    private func contemplationCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "leaf.fill")
                    .font(.caption2)
                Text("TODAY'S CONTEMPLATION")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.6)
            }
            .foregroundColor(Theme.accentDark)

            ViewThatFits(in: .vertical) {
                contemplationText(text, size: 17, spacing: 6)
                contemplationText(text, size: 15.5, spacing: 5)
                contemplationText(text, size: 14, spacing: 4)
                contemplationText(text, size: 12.5, spacing: 3)
                contemplationText(text, size: 11, spacing: 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [Theme.card, Theme.accent.opacity(0.06)],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Theme.accent.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Theme.cardShadow, radius: 18, x: 0, y: 8)
    }

    private func contemplationText(_ text: String, size: CGFloat, spacing: CGFloat) -> some View {
        Text(text)
            .font(.system(size: size, weight: .regular, design: .serif))
            .foregroundColor(Theme.ink.opacity(0.9))
            .lineSpacing(spacing)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
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
            appeared = false
            let pair = try await APIClient.shared.fetchWordOfDay()
            await MainActor.run {
                self.wordPair = pair
                self.isLoading = false
            }
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
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
