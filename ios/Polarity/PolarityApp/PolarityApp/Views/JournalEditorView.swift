import SwiftUI

struct JournalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var journalStore: JournalStore
    @State var date: Date
    @State var wordA: String
    @State var wordB: String
    @State var note: String
    @FocusState private var isEditorFocused: Bool
    @StateObject private var transcriber = SpeechTranscriber()
    @State private var showReflection = false
    @State private var noteBeforeDictation: String = ""

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

                // Editor + (after saving) the on-device reflection
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
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
                                .frame(minHeight: 200)
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .focused($isEditorFocused)
                                .disabled(showReflection)
                        }

                        if showReflection {
                            ReflectionCard(wordA: wordA, wordB: wordB, note: note)
                                .padding(.horizontal, 16)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // Footer
                Divider()
                    .padding(.horizontal, 20)

                HStack {
                    Text("\(wordCount) \(wordCount == 1 ? "word" : "words")")
                        .font(.caption)
                        .foregroundColor(Theme.muted)

                    Spacer()

                    Button {
                        Task {
                            if transcriber.isRecording {
                                transcriber.stop()
                            } else {
                                isEditorFocused = false
                                noteBeforeDictation = note.isEmpty
                                    ? ""
                                    : note.trimmingCharacters(in: .whitespacesAndNewlines)
                                await transcriber.start()
                            }
                        }
                    } label: {
                        Image(systemName: transcriber.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(transcriber.isRecording ? Theme.accent : Theme.accentDark)
                            .symbolEffect(.pulse, isActive: transcriber.isRecording)
                    }
                    .accessibilityLabel(transcriber.isRecording ? "Stop dictation" : "Start dictation")
                    .disabled(showReflection)
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
                    if showReflection {
                        Button("Done") { dismiss() }
                            .font(.body.weight(.semibold))
                    } else {
                        Button("Save") {
                            journalStore.addOrUpdate(date: date, wordA: wordA, wordB: wordB, note: note)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            isEditorFocused = false
                            transcriber.stop()
                            withAnimation { showReflection = true }
                        }
                        .font(.body.weight(.semibold))
                        .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: transcriber.transcript) { _, newValue in
                guard transcriber.isRecording else { return }
                if noteBeforeDictation.isEmpty {
                    note = newValue
                } else if newValue.isEmpty {
                    note = noteBeforeDictation
                } else {
                    note = noteBeforeDictation + " " + newValue
                }
            }
            .onDisappear { transcriber.stop() }
            .alert("Voice Journaling",
                   isPresented: Binding(
                       get: { transcriber.errorMessage != nil },
                       set: { if !$0 { transcriber.errorMessage = nil } }
                   )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(transcriber.errorMessage ?? "")
            }
            .presentationDragIndicator(.visible)
            .onAppear {
                if note.isEmpty {
                    isEditorFocused = true
                }
            }
        }
    }
}
