import Foundation
import Combine

@MainActor
final class JournalStore: ObservableObject {
    @Published private(set) var entries: [JournalEntry] = []

    private let fileName = "journal.json"
    private let settings: SettingsStore

    init(settings: SettingsStore) {
        self.settings = settings
        load()
    }

    func addOrUpdate(date: Date, wordA: String, wordB: String, note: String) {
        if let index = entries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            entries[index].note = note
            entries[index].wordA = wordA
            entries[index].wordB = wordB
        } else {
            let entry = JournalEntry(date: date, wordA: wordA, wordB: wordB, note: note)
            entries.append(entry)
        }
        entries.sort { $0.date > $1.date }
        save()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            entries.remove(at: index)
        }
        save()
    }

    func entry(for date: Date) -> JournalEntry? {
        entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func refreshStorageLocation() {
        load()
    }

    private func storageURL() -> URL {
        if settings.iCloudEnabled,
           let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            let docs = containerURL.appendingPathComponent("Documents", isDirectory: true)
            try? FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
            return docs.appendingPathComponent(fileName)
        }

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName)
    }

    private func load() {
        let url = storageURL()
        guard let data = try? Data(contentsOf: url) else {
            entries = []
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        entries = (try? decoder.decode([JournalEntry].self, from: data)) ?? []
        entries.sort { $0.date > $1.date }
    }

    private func save() {
        let url = storageURL()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}
