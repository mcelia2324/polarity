import SwiftUI

struct HistoryView: View {
    @State private var history: [WordPair] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    ProgressView("Loading...")
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else {
                    ForEach(history) { pair in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(pair.date)
                                .font(.caption)
                                .foregroundColor(Theme.muted)
                            Text("\(pair.wordA.capitalized) vs \(pair.wordB.capitalized)")
                                .font(.headline)
                                .foregroundColor(Theme.ink)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("History")
            .task {
                await load()
            }
        }
    }

    private func load() async {
        do {
            isLoading = true
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
