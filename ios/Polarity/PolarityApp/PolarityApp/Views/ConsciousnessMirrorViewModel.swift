import Foundation
import SwiftUI

/// Computes "Consciousness Mirror" stats entirely from on-device JournalStore data.
/// No backend, no AI. All inputs come from `[JournalEntry]`.
@MainActor
struct MirrorStats {

    // Headline stats
    let totalReflections: Int
    let currentStreak: Int
    let longestStreak: Int
    let wordsThisMonth: Int
    let reflectionsThisMonth: Int

    // Heatmap
    let heatmap: [HeatmapDay]
    let maxIntensity: Int

    // Higher-word leanings
    let topHigherWords: [HigherWord]

    var isEmpty: Bool { totalReflections == 0 }

    static func build(
        from entries: [JournalEntry],
        heatmapWeeks: Int = 20,
        topWordLimit: Int = 6,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> MirrorStats {

        var wordsByDay: [Date: Int] = [:]
        var hasEntryByDay: Set<Date> = []
        for entry in entries {
            let day = calendar.startOfDay(for: entry.date)
            wordsByDay[day, default: 0] += wordCount(entry.note)
            hasEntryByDay.insert(day)
        }

        let totalReflections = hasEntryByDay.count
        let current = currentStreak(days: hasEntryByDay, calendar: calendar, now: now)
        let longest = longestStreak(days: hasEntryByDay, calendar: calendar)

        let monthComps = calendar.dateComponents([.year, .month], from: now)
        var wordsThisMonth = 0
        var reflectionsThisMonth = 0
        for entry in entries {
            let c = calendar.dateComponents([.year, .month], from: entry.date)
            if c.year == monthComps.year && c.month == monthComps.month {
                wordsThisMonth += wordCount(entry.note)
                reflectionsThisMonth += 1
            }
        }

        let today = calendar.startOfDay(for: now)
        let totalDays = heatmapWeeks * 7
        guard let windowStart = calendar.date(byAdding: .day, value: -(totalDays - 1), to: today) else {
            return MirrorStats(totalReflections: totalReflections, currentStreak: current,
                               longestStreak: longest, wordsThisMonth: wordsThisMonth,
                               reflectionsThisMonth: reflectionsThisMonth, heatmap: [],
                               maxIntensity: 0, topHigherWords: [])
        }

        var heatmap: [HeatmapDay] = []
        heatmap.reserveCapacity(totalDays)
        var maxIntensity = 0
        var cursor = windowStart
        while cursor <= today {
            let count = wordsByDay[cursor] ?? 0
            maxIntensity = max(maxIntensity, count)
            heatmap.append(HeatmapDay(date: cursor, wordCount: count, hasEntry: count > 0 || hasEntryByDay.contains(cursor)))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        var counts: [String: Int] = [:]
        var displayName: [String: String] = [:]
        for entry in entries {
            let raw = entry.wordA.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !raw.isEmpty else { continue }
            let key = raw.lowercased()
            counts[key, default: 0] += 1
            displayName[key] = raw.capitalized
        }
        let topHigherWords = counts
            .sorted { lhs, rhs in
                lhs.value != rhs.value ? lhs.value > rhs.value : lhs.key < rhs.key
            }
            .prefix(topWordLimit)
            .map { HigherWord(word: displayName[$0.key] ?? $0.key.capitalized, count: $0.value) }

        return MirrorStats(
            totalReflections: totalReflections,
            currentStreak: current,
            longestStreak: longest,
            wordsThisMonth: wordsThisMonth,
            reflectionsThisMonth: reflectionsThisMonth,
            heatmap: heatmap,
            maxIntensity: maxIntensity,
            topHigherWords: Array(topHigherWords)
        )
    }

    private static func wordCount(_ note: String) -> Int {
        note.split { $0 == " " || $0 == "\n" || $0 == "\t" }.count
    }

    static func currentStreak(days: Set<Date>, calendar: Calendar, now: Date) -> Int {
        var checkDate = calendar.startOfDay(for: now)
        if !days.contains(checkDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            checkDate = yesterday
        }
        var streak = 0
        while days.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    static func longestStreak(days: Set<Date>, calendar: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }
        let sorted = days.sorted()
        var longest = 1
        var run = 1
        for i in 1..<sorted.count {
            if let expected = calendar.date(byAdding: .day, value: 1, to: sorted[i - 1]),
               calendar.isDate(expected, inSameDayAs: sorted[i]) {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
        }
        return longest
    }
}

struct HeatmapDay: Identifiable {
    let id = UUID()
    let date: Date
    let wordCount: Int
    let hasEntry: Bool

    /// Bucketed 0...4 intensity (GitHub style), scaled by the window's max.
    func level(maxIntensity: Int) -> Int {
        guard hasEntry else { return 0 }
        guard maxIntensity > 0 else { return 1 }
        let ratio = Double(wordCount) / Double(maxIntensity)
        switch ratio {
        case ..<0.001: return 1
        case ..<0.34:  return 1
        case ..<0.67:  return 2
        case ..<1.0:   return 3
        default:       return 4
        }
    }
}

struct HigherWord: Identifiable {
    var id: String { word }
    let word: String
    let count: Int
}
