import SwiftUI

struct TodayView: View {
    @State private var wordPair: WordPair?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showJournal = false
    @State private var selectedDefinition: DefinitionSheetItem?

    @ObservedObject var journalStore: JournalStore

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    if let pair = wordPair {
                        Spacer(minLength: 24)

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

                        Text("Reflect on the meanings, differences, and which calibrates higher.")
                            .font(.subheadline)
                            .foregroundColor(Theme.muted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 20)

                        DailyPromptCard(wordA: pair.wordA, wordB: pair.wordB)
                            .padding(.top, 20)

                        Spacer(minLength: 24)

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
                        .padding(.top, 8)

                        Text("Inspired by the work of David R. Hawkins.")
                            .font(.caption)
                            .foregroundColor(Theme.muted.opacity(0.7))
                            .padding(.top, 12)
                            .padding(.bottom, 20)

                    } else if isLoading {
                        Spacer()
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(Theme.accent)
                                .scaleEffect(1.5)
                            Text("Loading today's polarity…")
                                .font(.subheadline)
                                .foregroundColor(Theme.muted)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        Spacer()
                        Text(errorMessage ?? "Unable to load today's words.")
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                }
                .padding(.horizontal, 24)
                .frame(minHeight: proxy.size.height)
            }
            .scrollIndicators(.hidden)
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
