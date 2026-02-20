import SwiftUI

struct JournalView: View {
    @ObservedObject var journalStore: JournalStore
    @State private var selectedEntry: JournalEntry?

    var body: some View {
        NavigationView {
            List {
                if journalStore.entries.isEmpty {
                    Text("No journal entries yet.")
                        .foregroundColor(Theme.muted)
                } else {
                    ForEach(journalStore.entries) { entry in
                        Button {
                            selectedEntry = entry
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(entry.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(Theme.muted)
                                Text("\(entry.wordA.capitalized) vs \(entry.wordB.capitalized)")
                                    .font(.headline)
                                    .foregroundColor(Theme.ink)
                                Text(entry.note)
                                    .lineLimit(2)
                                    .foregroundColor(Theme.muted)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .onDelete(perform: journalStore.delete)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Journal")
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
}
