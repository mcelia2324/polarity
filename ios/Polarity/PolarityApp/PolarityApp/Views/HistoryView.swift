import SwiftUI

struct HistoryView: View {
    @ObservedObject var journalStore: JournalStore
    @State private var history: [WordPair] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedDefinition: HistoryDefinitionItem?

    var body: some View {
        NavigationView {
            ScrollView {
                if isLoading && history.isEmpty {
                    VStack(spacing: 16) {
                        Spacer(minLength: 80)
                        ProgressView()
                            .tint(Theme.accent)
                            .scaleEffect(1.5)
                        Text("Loading history…")
                            .font(.subheadline)
                            .foregroundColor(Theme.muted)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .readableWidth()
                } else if let errorMessage, history.isEmpty {
                    VStack(spacing: 16) {
                        Spacer(minLength: 80)
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.muted.opacity(0.4))
                        Text(errorMessage)
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
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .readableWidth()
                    .padding(.horizontal, 32)
                } else if history.isEmpty {
                    VStack(spacing: 16) {
                        Spacer(minLength: 80)
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 34))
                            .foregroundColor(Theme.accent.opacity(0.7))
                            .frame(width: 84, height: 84)
                            .background(Theme.accent.opacity(0.08))
                            .clipShape(Circle())
                        Text("No History Yet")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(Theme.ink)
                        Text("Past word pairs will appear here\nafter the first day.")
                            .font(.subheadline)
                            .foregroundColor(Theme.muted)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .readableWidth()
                    .padding(.horizontal, 32)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(history) { pair in
                            NavigationLink(destination: HistoryDetailView(pair: pair, journalStore: journalStore)) {
                                HistoryCard(
                                    pair: pair,
                                    hasJournalEntry: journalStore.entry(forDateString: pair.date) != nil,
                                    onTapWord: { word, definition in
                                        selectedDefinition = HistoryDefinitionItem(word: word, definition: definition)
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .readableWidth()
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("History")
            .refreshable {
                await load()
            }
            .task {
                await load()
            }
            .sheet(item: $selectedDefinition) { item in
                DefinitionSheet(word: item.word, definition: item.definition)
            }
        }
    }

    private func load() async {
        do {
            if history.isEmpty { isLoading = true }
            errorMessage = nil
            let items = try await APIClient.shared.fetchHistory(days: 60)
            await MainActor.run {
                history = items
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

private struct HistoryDefinitionItem: Identifiable {
    let id = UUID()
    let word: String
    let definition: String
}

private struct HistoryCard: View {
    let pair: WordPair
    let hasJournalEntry: Bool
    let onTapWord: (String, String) -> Void

    private var formattedDate: String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        parser.locale = Locale(identifier: "en_US_POSIX")
        guard let date = parser.date(from: pair.date) else { return pair.date }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(formattedDate)
                    .font(.caption.weight(.medium))
                    .foregroundColor(Theme.muted)
                Spacer()
                if hasJournalEntry {
                    Image(systemName: "book.closed.fill")
                        .font(.caption2)
                        .foregroundColor(Theme.accent.opacity(0.6))
                }
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(Theme.muted.opacity(0.4))
            }

            HStack(spacing: 10) {
                wordLabel(pair.wordA, definition: pair.wordADefinition)
                Text("vs")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.muted)
                wordLabel(pair.wordB, definition: pair.wordBDefinition)
            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    @ViewBuilder
    private func wordLabel(_ word: String, definition: String?) -> some View {
        if let definition {
            Button {
                onTapWord(word, definition)
            } label: {
                Text(word.capitalized)
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .buttonStyle(.plain)
        } else {
            Text(word.capitalized)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundColor(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}
