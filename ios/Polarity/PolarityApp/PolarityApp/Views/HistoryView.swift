import SwiftUI

struct HistoryView: View {
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
                    .padding(.horizontal, 32)
                } else if history.isEmpty {
                    VStack(spacing: 16) {
                        Spacer(minLength: 80)
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.muted.opacity(0.4))
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
                    .padding(.horizontal, 32)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(history) { pair in
                            HistoryCard(pair: pair, onTapWord: { word, definition in
                                selectedDefinition = HistoryDefinitionItem(word: word, definition: definition)
                            })
                        }
                    }
                    .padding(.horizontal, 20)
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
            Text(formattedDate)
                .font(.caption.weight(.medium))
                .foregroundColor(Theme.muted)

            HStack(spacing: 10) {
                wordLabel(pair.wordA, definition: pair.wordADefinition)
                Text("vs")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.muted)
                wordLabel(pair.wordB, definition: pair.wordBDefinition)
            }

            if pair.wordADefinition != nil || pair.wordBDefinition != nil {
                Text("Tap a word for its definition.")
                    .font(.caption2)
                    .foregroundColor(Theme.muted.opacity(0.6))
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
