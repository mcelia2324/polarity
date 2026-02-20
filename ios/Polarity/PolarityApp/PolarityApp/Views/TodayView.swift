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
                VStack(alignment: .leading, spacing: 20) {
                    if let pair = wordPair {
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
                            .foregroundColor(Theme.muted)
                            .padding(.horizontal, 6)

                        DailyPromptCard(wordA: pair.wordA, wordB: pair.wordB)
                    } else if isLoading {
                        ProgressView("Loading...")
                    } else {
                        Text(errorMessage ?? "Unable to load today's words.")
                            .foregroundColor(.red)
                    }

                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
                .frame(minHeight: proxy.size.height, alignment: .top)
            }
            .scrollIndicators(.hidden)
        }
        .task {
            await load()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                if wordPair != nil {
                    Button {
                        showJournal = true
                    } label: {
                        Label("Journal", systemImage: "square.and.pencil")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .padding(.vertical, 11)
                            .padding(.horizontal, 26)
                            .background(Theme.accent)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }

                Text("Inspired by the work of David R. Hawkins.")
                    .font(.footnote)
                    .foregroundColor(Theme.muted.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 6)
            .background(Theme.background.opacity(0.94))
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
        VStack(alignment: .leading, spacing: 8) {
            Label("Reflection Prompt", systemImage: "sparkles")
                .font(.footnote.weight(.semibold))
                .foregroundColor(Theme.accentDark)

            Text(prompt)
                .font(.subheadline)
                .foregroundColor(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
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
        .padding(24)
        .presentationDetents([.fraction(0.34), .medium])
        .presentationDragIndicator(.visible)
    }
}
