import AVFoundation
import Speech

/// Live dictation for the add/edit sheet: listens on the microphone and publishes the Chinese transcript as it grows.
final class SpeechInput: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var transcript = ""
    @Published private(set) var errorMessage: String?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    /// Bumped for every recording so a late callback from an old one is ignored.
    private var sessionID = 0

    func toggle() {
        if isRecording {
            stop()
        } else {
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
                    self.errorMessage = "请在“设置”中允许语音识别"
                    return
                }
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        guard granted else {
                            self.errorMessage = "请在“设置”中允许使用麦克风"
                            return
                        }
                        self.start()
                    }
                }
            }
        }
    }

    private func start() {
        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "语音识别暂时不可用"
            return
        }
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
            errorMessage = nil
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
            errorMessage = "无法开始录音"
            try? AVAudioSession.sharedInstance().setCategory(.ambient)
        }
    }
}
