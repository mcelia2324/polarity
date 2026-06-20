import SwiftUI

struct HistoryDetailView: View {
    let pair: WordPair
    @ObservedObject var journalStore: JournalStore
    @State private var selectedDefinition: DetailDefinitionItem?
    @State private var showEditor = false

    private var journalEntry: JournalEntry? {
        journalStore.entry(forDateString: pair.date)
    }

    private var formattedDate: String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        parser.locale = Locale(identifier: "en_US_POSIX")
        guard let date = parser.date(from: pair.date) else { return pair.date }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private var parsedDate: Date {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        parser.locale = Locale(identifier: "en_US_POSIX")
        return parser.date(from: pair.date) ?? Date()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                WordPairCard(
                    title: "\(pair.wordA.capitalized) vs \(pair.wordB.capitalized)",
                    subtitle: formattedDate,
                    wordA: pair.wordA,
                    wordB: pair.wordB,
                    onTapWordA: {
                        if let def = pair.wordADefinition {
                            selectedDefinition = DetailDefinitionItem(word: pair.wordA, definition: def)
                        }
                    },
                    onTapWordB: {
                        if let def = pair.wordBDefinition {
                            selectedDefinition = DetailDefinitionItem(word: pair.wordB, definition: def)
                        }
                    }
                )

                if let entry = journalEntry {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Your Reflection", systemImage: "book.closed")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(Theme.accentDark)
                            Spacer()
                            Text("\(entry.note.split(separator: " ").count) words")
                                .font(.caption2)
                                .foregroundColor(Theme.muted.opacity(0.6))
                        }

                        Text(entry.note)
                            .font(.subheadline)
                            .foregroundColor(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                    .onTapGesture {
                        showEditor = true
                    }

                    Text("Tap to edit your reflection.")
                        .font(.caption)
                        .foregroundColor(Theme.muted.opacity(0.6))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 28))
                            .foregroundColor(Theme.muted.opacity(0.4))

                        Text("No reflection for this day yet.")
                            .font(.subheadline)
                            .foregroundColor(Theme.muted)

                        Button {
                            showEditor = true
                        } label: {
                            Text("Write a Reflection")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Theme.accent)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .cardStyle()
                }
            }
            .padding(.horizontal, 20)
            .readableWidth()
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle(formattedDate)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditor) {
            JournalEditorView(
                journalStore: journalStore,
                date: parsedDate,
                wordA: pair.wordA,
                wordB: pair.wordB,
                note: journalEntry?.note ?? ""
            )
        }
        .sheet(item: $selectedDefinition) { item in
            DefinitionSheet(word: item.word, definition: item.definition)
        }
    }
}

private struct DetailDefinitionItem: Identifiable {
    let id = UUID()
    let word: String
    let definition: String
}
