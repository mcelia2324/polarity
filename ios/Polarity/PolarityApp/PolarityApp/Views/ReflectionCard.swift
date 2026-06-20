import SwiftUI

/// Shows an on-device reflection that "talks back" to the user's journal entry.
/// Self-contained: owns its loading/result state; callers just pass the three inputs.
struct ReflectionCard: View {
    let wordA: String
    let wordB: String
    let note: String

    @State private var reflection: ReflectionService.Reflection?
    @State private var isThinking = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                Text("Reflection")
                    .font(.footnote.weight(.semibold))
                Spacer()
                if let r = reflection, r.isOnDevice {
                    Label("On-device", systemImage: "lock.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(Theme.muted)
                        .labelStyle(.titleAndIcon)
                }
            }
            .foregroundColor(Theme.accentDark)

            if isThinking {
                HStack(spacing: 10) {
                    ProgressView().tint(Theme.accent)
                    Text("Reflecting on what you wrote…")
                        .font(.subheadline)
                        .foregroundColor(Theme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if let r = reflection {
                Text(r.text)
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundColor(Theme.ink)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }

            if reflection != nil && !isThinking {
                Button {
                    Task { await generate() }
                } label: {
                    Label("Reflect again", systemImage: "arrow.clockwise")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.accentDark)
                }
                .padding(.top, 2)
            }
        }
        .cardStyle()
        .task(id: note) { await generate() }
    }

    @MainActor
    private func generate() async {
        guard !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            reflection = nil
            return
        }
        isThinking = true
        let result = await ReflectionService.shared.reflect(wordA: wordA, wordB: wordB, note: note)
        withAnimation(.easeInOut(duration: 0.25)) {
            reflection = result
            isThinking = false
        }
    }
}
