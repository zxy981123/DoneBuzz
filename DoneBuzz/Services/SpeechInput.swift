import AVFoundation
import Speech

/// Live dictation for the add/edit sheet: listens on the microphone and publishes the transcript as it grows,
/// in whichever language the app is set to.
final class SpeechInput: ObservableObject {
    /// Why dictation could not start. The sheet turns this into text in the current language.
    enum Problem {
        case speechDenied, microphoneDenied, unavailable, cannotRecord
    }

    @Published private(set) var isRecording = false
    @Published private(set) var transcript = ""
    @Published private(set) var problem: Problem?

    /// Kept alive for as long as a recognition task is running.
    private var recognizer: SFSpeechRecognizer?
    private var locale = Locale(identifier: "zh-CN")
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    /// Bumped for every recording so a late callback from an old one is ignored.
    private var sessionID = 0

    /// Starts listening in `locale`, or stops if already listening.
    func toggle(locale: Locale) {
        if isRecording {
            stop()
        } else {
            self.locale = locale
            requestPermissionsAndStart()
        }
    }

    func stop() {
        guard isRecording else { return }
        isRecording = false
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        // Ending the audio lets the recognizer deliver its final result.
        request?.endAudio()
        request = nil
        // Hand the audio session back so the completion chime keeps respecting the silent switch.
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        try? session.setCategory(.ambient)
    }

    private func requestPermissionsAndStart() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                guard status == .authorized else {
                    self.problem = .speechDenied
                    return
                }
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        guard granted else {
                            self.problem = .microphoneDenied
                            return
                        }
                        self.start()
                    }
                }
            }
        }
    }

    private func start() {
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            problem = .unavailable
            return
        }
        self.recognizer = recognizer
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            self.request = request

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
                throw NSError(domain: "SpeechInput", code: 1)
            }
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                request.append(buffer)
            }
            engine.prepare()
            try engine.start()

            sessionID += 1
            let id = sessionID
            problem = nil
            transcript = ""
            isRecording = true

            recognizer.recognitionTask(with: request) { [weak self] result, error in
                DispatchQueue.main.async {
                    guard let self, self.sessionID == id else { return }
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                    }
                    if error != nil || result?.isFinal == true {
                        self.stop()
                    }
                }
            }
        } catch {
            engine.inputNode.removeTap(onBus: 0)
            request = nil
            problem = .cannotRecord
            try? AVAudioSession.sharedInstance().setCategory(.ambient)
        }
    }
}
