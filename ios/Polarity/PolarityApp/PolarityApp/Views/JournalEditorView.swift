import SwiftUI

struct JournalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var journalStore: JournalStore
    @State var date: Date
    @State var wordA: String
    @State var wordB: String
    @State var note: String
    @FocusState private var isEditorFocused: Bool

    private var wordCount: Int {
        note.split(separator: " ").count
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(dateLabel)
                        .font(.caption.weight(.medium))
                        .foregroundColor(Theme.muted)

                    Text("\(wordA.capitalized) vs \(wordB.capitalized)")
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .foregroundColor(Theme.ink)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)

                Divider()
                    .padding(.horizontal, 20)

                // Editor
                ZStack(alignment: .topLeading) {
                    if note.isEmpty {
                        Text("What comes to mind when you reflect on these two words? How do they show up in your life today?")
                            .font(.body)
                            .foregroundColor(Theme.muted.opacity(0.5))
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $note)
                        .font(.body)
                        .foregroundColor(Theme.ink)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .focused($isEditorFocused)
                }
                .frame(maxHeight: .infinity)

                // Footer
                Divider()
                    .padding(.horizontal, 20)

                HStack {
                    Text("\(wordCount) \(wordCount == 1 ? "word" : "words")")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .background(Theme.card)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") { isEditorFocused = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        journalStore.addOrUpdate(date: date, wordA: wordA, wordB: wordB, note: note)
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if note.isEmpty {
                    isEditorFocused = true
                }
            }
        }
    }
}
