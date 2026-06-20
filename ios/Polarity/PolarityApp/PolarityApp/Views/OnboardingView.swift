import SwiftUI

/// First-run onboarding that delivers the "wow" in under a minute: it explains the practice,
/// then hands the user TODAY's real polarity and lets them write one sentence and feel the
/// on-device reflection talk back — before they've journaled a single day.
struct OnboardingView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var journalStore: JournalStore
    @ObservedObject var notificationManager: NotificationManager
    var onFinish: () -> Void

    @State private var step = 0
    private let lastStep = 3

    var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: practiceStep
                    case 2:
                        OnboardingTasteView(journalStore: journalStore) { advance() }
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                    default: finishStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)

                pageDots
                    .padding(.bottom, 24)
            }
            .readableWidth()
        }
    }

    private func advance() {
        withAnimation(.easeInOut(duration: 0.35)) {
            if step >= lastStep { onFinish() } else { step += 1 }
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0...lastStep, id: \.self) { i in
                Circle()
                    .fill(i == step ? Theme.accent : Theme.muted.opacity(0.3))
                    .frame(width: 7, height: 7)
            }
        }
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "circle.lefthalf.filled")
                .font(.system(size: 56))
                .foregroundColor(Theme.accent)
                .padding(.bottom, 28)
            Text("Polarity")
                .font(.system(size: 40, weight: .semibold, design: .serif))
                .foregroundColor(Theme.ink)
            Text("Two contrasting words each day —\na moment to notice where you are,\nand choose where to rise.")
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.top, 16)
                .padding(.horizontal, 32)
            Spacer()
            primaryButton("Begin") { advance() }
                .padding(.horizontal, 28)
                .padding(.bottom, 12)
        }
    }

    // MARK: - Step 1: The practice

    private var practiceStep: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)
            Text("The Daily Practice")
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundColor(Theme.ink)
                .padding(.bottom, 8)
            Text("Simple, and only a minute a day.")
                .font(.subheadline)
                .foregroundColor(Theme.muted)
                .padding(.bottom, 32)

            VStack(spacing: 20) {
                PracticeRow(icon: "circle.lefthalf.filled",
                            title: "Notice the polarity",
                            subtitle: "Each day brings two contrasting words — a higher and a lower expression of consciousness.")
                PracticeRow(icon: "sparkles",
                            title: "Reflect",
                            subtitle: "Sit with where each one shows up in your day, without judgment.")
                PracticeRow(icon: "square.and.pencil",
                            title: "Take one step",
                            subtitle: "Write a single, honest move toward the higher word.")
            }
            .padding(.horizontal, 24)

            Spacer()
            primaryButton("Continue") { advance() }
                .padding(.horizontal, 28)
                .padding(.bottom, 12)
        }
    }

    // MARK: - Step 3: Finish

    private var finishStep: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 52))
                .foregroundColor(Theme.accent)
                .padding(.bottom, 24)
            Text("You're ready")
                .font(.system(size: 30, weight: .semibold, design: .serif))
                .foregroundColor(Theme.ink)
            Text("Come back each day for a new polarity. A gentle reminder helps the practice take root.")
                .font(.system(size: 16, weight: .regular, design: .serif))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 14)
                .padding(.horizontal, 32)

            Toggle(isOn: Binding(
                get: { settings.notificationsEnabled },
                set: { newValue in
                    settings.notificationsEnabled = newValue
                    if newValue {
                        Task {
                            await notificationManager.requestAuthorization()
                            notificationManager.updateServerToggle(settings: settings)
                        }
                    }
                }
            )) {
                Label("Daily reminder", systemImage: "bell")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Theme.ink)
            }
            .tint(Theme.accent)
            .padding(16)
            .background(Theme.card)
            .cornerRadius(16)
            .padding(.horizontal, 28)
            .padding(.top, 28)

            Spacer()
            primaryButton("Enter Polarity") { advance() }
                .padding(.horizontal, 28)
                .padding(.bottom, 12)
        }
    }

    // MARK: - Shared button

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Theme.accent)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
    }
}

private struct PracticeRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Theme.accent)
                .frame(width: 44, height: 44)
                .background(Theme.accent.opacity(0.1))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundColor(Theme.ink)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - The live taste

private struct TasteDefinition: Identifiable {
    let id = UUID()
    let word: String
    let definition: String
}

private struct OnboardingTasteView: View {
    @ObservedObject var journalStore: JournalStore
    var onContinue: () -> Void

    @State private var pair: WordPair?
    @State private var isLoading = true
    @State private var note = ""
    @State private var showReflection = false
    @State private var selectedDefinition: TasteDefinition?
    @FocusState private var focused: Bool

    private var trimmedNote: String { note.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Text("Try it now")
                        .font(.system(size: 26, weight: .semibold, design: .serif))
                        .foregroundColor(Theme.ink)
                    Text("Here's today's polarity. Tap a word to see what it means, then write one honest sentence.")
                        .font(.subheadline)
                        .foregroundColor(Theme.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 24)

                if let pair {
                    WordPairCard(
                        title: "Today's Polarity",
                        subtitle: "Begin here",
                        wordA: pair.wordA,
                        wordB: pair.wordB,
                        onTapWordA: { showDefinition(pair.wordA, pair.wordADefinition) },
                        onTapWordB: { showDefinition(pair.wordB, pair.wordBDefinition) }
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Where does \(pair.wordA.capitalized) or \(pair.wordB.capitalized) show up for you today?")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(Theme.accentDark)
                        TextField("One honest sentence…", text: $note, axis: .vertical)
                            .lineLimit(2...5)
                            .font(.body)
                            .foregroundColor(Theme.ink)
                            .focused($focused)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()

                    if showReflection && !trimmedNote.isEmpty {
                        ReflectionCard(wordA: pair.wordA, wordB: pair.wordB, note: note)
                            .transition(.opacity)
                    } else {
                        Button {
                            focused = false
                            withAnimation(.easeInOut) { showReflection = true }
                        } label: {
                            Label("Reflect on it", systemImage: "sparkles")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(trimmedNote.isEmpty ? Theme.muted.opacity(0.25) : Theme.accent)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        .disabled(trimmedNote.isEmpty)
                    }
                } else if isLoading {
                    VStack(spacing: 12) {
                        Spacer(minLength: 60)
                        ProgressView().tint(Theme.accent).scaleEffect(1.3)
                        Text("Loading today's words…")
                            .font(.subheadline).foregroundColor(Theme.muted)
                    }
                } else {
                    Text("Couldn't load today's words right now — you can still continue and start fresh inside.")
                        .font(.subheadline)
                        .foregroundColor(Theme.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 40)
                }

                Button(action: continueTapped) {
                    Text(showReflection ? "Continue" : "Skip for now")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(showReflection ? .white : Theme.accentDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, showReflection ? 15 : 8)
                        .background(showReflection ? Theme.accent : Color.clear)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .task { await load() }
        .sheet(item: $selectedDefinition) { item in
            VStack(alignment: .leading, spacing: 18) {
                Text(item.word.capitalized)
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                    .foregroundColor(Theme.accentDark)
                Text(item.definition)
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundColor(Theme.ink)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .background(Theme.card)
            .presentationDetents([.fraction(0.34), .medium])
            .presentationDragIndicator(.visible)
        }
    }

    private func showDefinition(_ word: String, _ definition: String?) {
        selectedDefinition = TasteDefinition(word: word, definition: definition ?? "Definition unavailable.")
    }

    private func continueTapped() {
        // If they wrote a real sentence, keep it as their first journal entry — an instant start.
        if let pair, !trimmedNote.isEmpty {
            journalStore.addOrUpdate(date: Date(), wordA: pair.wordA, wordB: pair.wordB, note: trimmedNote)
        }
        onContinue()
    }

    private func load() async {
        do {
            let fetched = try await APIClient.shared.fetchWordOfDay()
            await MainActor.run {
                self.pair = fetched
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.isLoading = false }
        }
    }
}
