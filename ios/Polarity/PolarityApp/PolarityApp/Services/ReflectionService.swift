import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Generates a short, warm reflection that mirrors the user's journal entry for the
/// day's polarity (wordA vs wordB) and ends with one gentle deepening question.
///
/// Runs ENTIRELY on-device via Apple's Foundation Models framework (iOS 26+, Apple-
/// Intelligence-capable devices). Journal text never leaves the phone, and there is zero
/// server cost. On iOS 18 to 25, ineligible hardware, or when Apple Intelligence is off, it
/// returns a thoughtful templated reflection instead, so every user always gets something.
actor ReflectionService {
    static let shared = ReflectionService()

    /// Why we fell back to the template (for optional UI messaging / debugging).
    enum Source: Equatable {
        case onDevice
        case templatedUnsupportedOS        // iOS < 26
        case templatedDeviceNotEligible    // capable OS, incapable chip
        case templatedAppleIntelligenceOff // user hasn't enabled Apple Intelligence
        case templatedModelNotReady        // model still downloading
        case templatedError                // generation failed; degraded gracefully
    }

    struct Reflection: Equatable {
        let text: String
        let source: Source
        var isOnDevice: Bool { source == .onDevice }
    }

    /// True when the on-device model is ready right now.
    func isOnDeviceAvailable() -> Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        #endif
        return false
    }

    /// Produce a reflection. Never throws, and always returns something to show the user.
    func reflect(wordA: String, wordB: String, note: String) async -> Reflection {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return Reflection(text: emptyNotePrompt(wordA: wordA, wordB: wordB), source: .templatedError)
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return await generateOnDevice(wordA: wordA, wordB: wordB, note: trimmed)
            case .unavailable(.deviceNotEligible):
                return template(wordA: wordA, wordB: wordB, note: trimmed, source: .templatedDeviceNotEligible)
            case .unavailable(.appleIntelligenceNotEnabled):
                return template(wordA: wordA, wordB: wordB, note: trimmed, source: .templatedAppleIntelligenceOff)
            case .unavailable(.modelNotReady):
                return template(wordA: wordA, wordB: wordB, note: trimmed, source: .templatedModelNotReady)
            case .unavailable:
                return template(wordA: wordA, wordB: wordB, note: trimmed, source: .templatedError)
            }
        }
        #endif

        return template(wordA: wordA, wordB: wordB, note: trimmed, source: .templatedUnsupportedOS)
    }

    // MARK: - On-device generation

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func generateOnDevice(wordA: String, wordB: String, note: String) async -> Reflection {
        let instructions = """
        You are a warm, grounded reflection companion inside a daily journaling app about \
        contrasting word pairs (inspired by David R. Hawkins' Map of Consciousness). \
        The user has just journaled about the polarity between two words. \
        Mirror back what THEY wrote, being specific to their words. Do not invent facts they \
        did not say, and do not give advice or diagnose. Be encouraging and concise. \
        Write 2 to 4 sentences total, then end with exactly ONE gentle, open-ended question \
        that helps them go a little deeper. Do not use lists, headings, or emoji. \
        Refer to the two words naturally, with a calm, kind tone. Use simple punctuation, and \
        never use em dashes, en dashes, or double hyphens.
        """

        let prompt = """
        Today's polarity: "\(wordA)" versus "\(wordB)".
        What I journaled:
        \(note)
        """

        do {
            let session = LanguageModelSession(instructions: instructions)
            let options = GenerationOptions(temperature: 0.7)
            let response = try await session.respond(to: prompt, options: options)
            let text = normalizeDashes(response.content).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else {
                return template(wordA: wordA, wordB: wordB, note: note, source: .templatedError)
            }
            return Reflection(text: text, source: .onDevice)
        } catch {
            // Covers guardrail violations, context-window overflow, model unload, etc.
            // We never surface a raw error to the user; we degrade gracefully.
            return template(wordA: wordA, wordB: wordB, note: note, source: .templatedError)
        }
    }
    #endif

    // MARK: - Templated fallback (iOS 18+, no model required)

    private func template(wordA: String, wordB: String, note: String, source: Source) -> Reflection {
        let a = wordA.capitalized
        let b = wordB.capitalized
        let leaning = leaningHint(note: note, wordA: wordA, wordB: wordB)

        let openers = [
            "Thank you for sitting with \(a) and \(b) today.",
            "There's real honesty in how you held \(a) against \(b).",
            "It takes presence to notice where \(a) and \(b) meet in a day."
        ]
        let mirrors = [
            "What you wrote suggests you're feeling the pull \(leaning), and naming that is itself a kind of clarity.",
            "Reading it back, the tension between these two seems alive for you right now \(leaning).",
            "You seem to be tracking, in your own words, where you lean \(leaning)."
        ]
        let questions = [
            "What would it look like to take one small step toward \(a) before tomorrow?",
            "Where in your day did \(b) quietly make the choice for you?",
            "If \(a) had a little more room tomorrow, what is the first thing that would change?"
        ]

        // Deterministic pick so the same entry yields a stable reflection.
        let seed = abs(note.hashValue)
        let text = "\(openers[seed % openers.count]) "
                 + "\(mirrors[(seed / 3) % mirrors.count]) "
                 + "\(questions[(seed / 7) % questions.count])"
        return Reflection(text: text, source: source)
    }

    /// Light, fully local heuristic: which word does the note mention more?
    private func leaningHint(note: String, wordA: String, wordB: String) -> String {
        let lower = note.lowercased()
        let aCount = occurrences(of: wordA.lowercased(), in: lower)
        let bCount = occurrences(of: wordB.lowercased(), in: lower)
        if aCount > bCount { return "toward \(wordA.capitalized)" }
        if bCount > aCount { return "toward \(wordB.capitalized)" }
        return "between the two"
    }

    /// Replace em/en dashes and double hyphens with plain punctuation (avoids the machine-written look).
    private func normalizeDashes(_ text: String) -> String {
        var t = text
        for sep in [" — ", " – ", " -- ", "—", "--"] {
            t = t.replacingOccurrences(of: sep, with: ", ")
        }
        return t.replacingOccurrences(of: " ,", with: ",")
    }

    private func occurrences(of needle: String, in haystack: String) -> Int {
        guard !needle.isEmpty else { return 0 }
        return haystack.components(separatedBy: needle).count - 1
    }

    private func emptyNotePrompt(wordA: String, wordB: String) -> String {
        "When you're ready, even one sentence about where \(wordA.capitalized) or "
        + "\(wordB.capitalized) showed up today is enough to reflect on. What's the first "
        + "thing that comes to mind?"
    }
}
