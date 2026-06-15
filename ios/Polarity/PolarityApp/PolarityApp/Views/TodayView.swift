import SwiftUI

struct TodayView: View {
    @State private var wordPair: WordPair?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showJournal = false
    @State private var selectedDefinition: DefinitionSheetItem?

    // Animation states
    @State private var showCard = false
    @State private var showPrompt = false
    @State private var showButton = false

    @ObservedObject var journalStore: JournalStore

    private var streak: Int { journalStore.currentStreak }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if let pair = wordPair {
                    VStack(spacing: 0) {
                        // Streak badge
                        if streak > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("\(streak)-day streak")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Theme.ink)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Theme.card)
                            .clipShape(Capsule())
                            .opacity(showCard ? 1 : 0)
                        }

                        WordPairCard(
                            title: "Today's Polarity",
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
                            }
                        )
                        .padding(.top, 12)
                        .opacity(showCard ? 1 : 0)
                        .offset(y: showCard ? 0 : 30)

                        Text("Reflect on the meanings, differences, and which calibrates higher.")
                            .font(.subheadline)
                            .foregroundColor(Theme.muted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 20)
                            .opacity(showCard ? 1 : 0)
                            .offset(y: showCard ? 0 : 20)

                        DailyPromptCard(wordA: pair.wordA, wordB: pair.wordB)
                            .padding(.top, 20)
                            .opacity(showPrompt ? 1 : 0)
                            .offset(y: showPrompt ? 0 : 24)

                        // Daily quote
                        if let quote = pair.quote {
                            VStack(spacing: 8) {
                                Text("\"\(quote)\"")
                                    .font(.system(size: 16, weight: .regular, design: .serif))
                                    .italic()
                                    .foregroundColor(Theme.ink.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let author = pair.quoteAuthor {
                                    Text("— \(author)")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(Theme.muted)
                                }
                            }
                            .padding(.horizontal, 32)
                            .padding(.top, 32)
                            .opacity(showButton ? 1 : 0)
                        }

                    }
                    .padding(.horizontal, 24)
                    .readableWidth()
                    .padding(.top, 16)
                } else if isLoading {
                    VStack(spacing: 16) {
                        Spacer(minLength: 120)
                        ProgressView()
                            .tint(Theme.accent)
                            .scaleEffect(1.5)
                        Text("Loading today's polarity…")
                            .font(.subheadline)
                            .foregroundColor(Theme.muted)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 16) {
                        Spacer(minLength: 120)
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
                    .frame(maxWidth: .infinity)
                }
            }
            .scrollIndicators(.hidden)
            .refreshable {
                await load()
            }

            // Pinned Journal button at bottom
            if wordPair != nil {
                Button {
                    showJournal = true
                } label: {
                    Label("Journal", systemImage: "square.and.pencil")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Theme.accent)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .readableWidth()
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 18)

                Text("Inspired by the work of David R. Hawkins.")
                    .font(.caption)
                    .foregroundColor(Theme.muted.opacity(0.5))
                    .padding(.bottom, 8)
                    .opacity(showButton ? 1 : 0)
            }
        }
        .task {
            await load()
        }
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
            DefinitionSheetView(item: item)
        }
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
            // Reset animations for fresh entrance
            showCard = false
            showPrompt = false
            showButton = false
            let pair = try await APIClient.shared.fetchWordOfDay()
            await MainActor.run {
                self.wordPair = pair
                self.isLoading = false
            }
            // Staggered entrance animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showCard = true
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showPrompt = true
            }
            try? await Task.sleep(nanoseconds: 150_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showButton = true
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

private struct DailyPromptCard: View {
    let wordA: String
    let wordB: String

    private var prompt: String {
        "What one action today would move you from \(wordB.capitalized) toward \(wordA.capitalized)?"
    }

    var body: some View {
        VStack(spacing: 10) {
            Label("Reflection Prompt", systemImage: "sparkles")
                .font(.footnote.weight(.semibold))
                .foregroundColor(Theme.accentDark)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(prompt)
                .font(.subheadline)
                .foregroundColor(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cardStyle()
    }
}

private struct DefinitionSheetItem: Identifiable {
    let id = UUID()
    let word: String
    let definition: String
}

private struct DefinitionSheetView: View {
    let item: DefinitionSheetItem

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(item.word.capitalized)
                .font(.system(size: 30, weight: .semibold, design: .serif))
                .foregroundColor(Theme.accentDark)
            Text(item.definition)
                .font(.system(size: 20, weight: .regular, design: .rounded))
                .foregroundColor(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Theme.card)
        .presentationDetents([.fraction(0.34), .medium])
        .presentationDragIndicator(.visible)
    }
}
