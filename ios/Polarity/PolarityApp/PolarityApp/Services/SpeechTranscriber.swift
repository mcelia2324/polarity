import Foundation
import Combine
import AVFoundation
import Speech

/// Live, on-device speech-to-text for the journal editor (free and private — no server).
/// Matches Polarity's @MainActor ObservableObject service convention.
@MainActor
final class SpeechTranscriber: ObservableObject {

    /// The latest transcription of the CURRENT dictation session only (reset to "" on start).
    @Published private(set) var transcript: String = ""

    /// True while the mic is actively capturing.
    @Published private(set) var isRecording = false

    /// Non-nil when something went wrong (permission denied, recognizer unavailable, etc.).
    @Published var errorMessage: String?

    /// True once we've confirmed both speech + mic permissions are granted.
    @Published private(set) var isAuthorized = false

    private let recognizer = SFSpeechRecognizer(locale: Locale.current)
        ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    // MARK: - Permissions

    /// Requests Speech Recognition + Microphone authorization. True only if BOTH are granted.
    func requestAuthorization() async -> Bool {
        let speechStatus: SFSpeechRecognizerAuthorizationStatus =
            await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status)
                }
            }

        guard speechStatus == .authorized else {
            isAuthorized = false
            errorMessage = "Speech recognition permission is off. You can enable it in Settings."
            return false
        }

        let micGranted = await requestMicrophonePermission()
        guard micGranted else {
            isAuthorized = false
            errorMessage = "Microphone access is off. You can enable it in Settings."
            return false
        }

        guard let recognizer, recognizer.isAvailable else {
            isAuthorized = false
            errorMessage = "Speech recognition is not available right now."
            return false
        }

        isAuthorized = true
        return true
    }

    private func requestMicrophonePermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Recording control

    func start() async {
        guard !isRecording else { return }

        if !isAuthorized {
            let ok = await requestAuthorization()
            guard ok else { return }
        }

        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognition is not available right now."
            return
        }

        transcript = ""
        errorMessage = nil

        do {
            try configureAudioSession()
        } catch {
            errorMessage = "Could not start audio: \(error.localizedDescription)"
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        request.addsPunctuation = true
        self.request = request

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        guard recordingFormat.channelCount > 0 else {
            errorMessage = "No audio input available."
            stop()
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "Could not start recording: \(error.localizedDescription)"
            stop()
            return
        }

        isRecording = true

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.stop()
                }
            }
        }
    }

    func stop() {
        guard isRecording || task != nil || request != nil else { return }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        request?.endAudio()
        task?.cancel()

        request = nil
        task = nil
        isRecording = false

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }
}
