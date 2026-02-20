import SwiftUI

struct JournalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var journalStore: JournalStore
    @State var date: Date
    @State var wordA: String
    @State var wordB: String
    @State var note: String

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(wordA.capitalized) vs \(wordB.capitalized)")
                    .font(.title3.weight(.semibold))
                TextEditor(text: $note)
                    .frame(minHeight: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2))
                    )
                Spacer()
            }
            .padding()
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        journalStore.addOrUpdate(date: date, wordA: wordA, wordB: wordB, note: note)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
