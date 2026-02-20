import Foundation

struct JournalEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var wordA: String
    var wordB: String
    var note: String
    var createdAt: Date

    init(date: Date, wordA: String, wordB: String, note: String) {
        self.id = UUID()
        self.date = date
        self.wordA = wordA
        self.wordB = wordB
        self.note = note
        self.createdAt = Date()
    }
}
