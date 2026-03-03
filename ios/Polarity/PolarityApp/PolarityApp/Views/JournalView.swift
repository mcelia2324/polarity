import SwiftUI

struct JournalView: View {
    @ObservedObject var journalStore: JournalStore
    @State private var selectedEntry: JournalEntry?
    @State private var searchText = ""

    private var filteredEntries: [JournalEntry] {
        if searchText.isEmpty {
            return journalStore.entries
        }
        let query = searchText.lowercased()
        return journalStore.entries.filter {
            $0.wordA.lowercased().contains(query) ||
            $0.wordB.lowercased().contains(query) ||
            $0.note.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                if journalStore.entries.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredEntries) { entry in
                            JournalEntryCard(entry: entry)
                                .onTapGesture {
                                    selectedEntry = entry
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        if let index = journalStore.entries.firstIndex(of: entry) {
                                            journalStore.delete(at: IndexSet(integer: index))
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
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
            .navigationTitle("Journal")
            .searchable(text: $searchText, prompt: "Search entries…")
        }
        .sheet(item: $selectedEntry) { entry in
            JournalEditorView(
                journalStore: journalStore,
                date: entry.date,
                wordA: entry.wordA,
                wordB: entry.wordB,
                note: entry.note
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 80)

            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(Theme.muted.opacity(0.4))

            Text("No Entries Yet")
                .font(.title3.weight(.semibold))
                .foregroundColor(Theme.ink)

            Text("When you journal from the Today tab,\nyour reflections will appear here.")
                .font(.subheadline)
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }
}

private struct JournalEntryCard: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.date, format: .dateTime.month(.wide).day().year())
                    .font(.caption.weight(.medium))
                    .foregroundColor(Theme.muted)
                Spacer()
                Text("\(entry.note.split(separator: " ").count) words")
                    .font(.caption2)
                    .foregroundColor(Theme.muted.opacity(0.6))
            }

            Text("\(entry.wordA.capitalized) vs \(entry.wordB.capitalized)")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundColor(Theme.ink)

            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(.subheadline)
                    .foregroundColor(Theme.muted)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
