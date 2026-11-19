import AVFoundation
import UIKit

/// The "reward" fired when an item is completed: a haptic thump on tap, a success buzz as the
/// coin pops, and a short 8-bit "hop + coin" sound.
/// The sound is synthesized in code, so the project needs no audio asset.
final class FeedbackService {
    static let shared = FeedbackService()

    private let impact = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private var player: AVAudioPlayer?

    private static let sampleRate: Double = 44_100

    private init() {
        // .ambient respects the silent switch and does not interrupt music.
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        player = try? AVAudioPlayer(data: Self.makeHopAndCoin(), fileTypeHint: AVFileType.wav.rawValue)
        player?.prepareToPlay()
    }

    /// The day's last item is done: a longer drum-roll and finish.
    func dayCleared() {
        // Starts once the normal completion buzz has finished.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [haptics, notification] in
            if !haptics.play(.dayCleared) {
                notification.notificationOccurred(.success)
            }
        }
    }

    /// Warms up the Taptic Engine so the first buzz has no delay.
    func prepare() {
        haptics.prepare()
        impact.prepare()
        notification.prepare()
    }

    private let haptics = HapticPlayer()

    func taskCompleted() {
        // A thump on tap, a short buzz, rising taps up to the coin pop, then two soft echoes.
        if !haptics.play(.taskCompleted) {
            impact.impactOccurred()
            // Lands with the coin, which pops at the top of the cat's hop.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { [notification] in
                notification.notificationOccurred(.success)
            }
        }
        // Dictation switches the audio session to recording; make sure the chime can still play.
        let session = AVAudioSession.sharedInstance()
        if session.category != .ambient {
            try? session.setCategory(.ambient)
        }
        try? session.setActive(true)
        player?.currentTime = 0
        player?.play()
    }

    // MARK: - Sound synthesis

    /// A quick upward "boing" for the hop, then a bright G-C-E-G coin arpeggio, as 16-bit mono WAV data.
    private static func makeHopAndCoin() -> Data {
        let duration: Double = 0.85
        let count = Int(sampleRate * duration)
        var mix = [Double](repeating: 0, count: count)

        // 1. The hop: a 0.16 s sweep from 300 Hz up to 820 Hz.
        let hopLength = 0.16
        var phase: Double = 0
        for i in 0..<Int(sampleRate * hopLength) {
            let t = Double(i) / sampleRate
            let frequency = 300 * pow(820.0 / 300.0, t / hopLength)
            phase += 2 * Double.pi * frequency / sampleRate
            let envelope = min(t / 0.004, 1) * (1 - t / hopLength)
            mix[i] += 0.55 * envelope * softSquare(phase)
        }

        // 2. The coin: four quick notes starting as the cat reaches the top; the last one rings on.
        let notes: [(frequency: Double, start: Double, decay: Double)] = [
            (783.99, 0.20, 18),   // G5
            (1046.50, 0.26, 18),  // C6
            (1318.51, 0.32, 18),  // E6
            (1567.98, 0.38, 6),   // G6
        ]
        for note in notes {
            let first = Int(sampleRate * note.start)
            for i in first..<count {
                let local = Double(i - first) / sampleRate
                let envelope = min(local / 0.003, 1) * exp(-local * note.decay)
                if local > 0.05 && envelope < 0.0005 { break }
                mix[i] += 0.5 * envelope * softSquare(2 * Double.pi * note.frequency * local)
            }
        }

        let samples = mix.map { value -> Int16 in
            let clamped = max(-1.0, min(1.0, value * 0.6))
            return Int16(clamped * Double(Int16.max))
        }
        return wav(samples)
    }

    /// A square wave built from its first three odd harmonics: chiptune-flavoured but not harsh.
    private static func softSquare(_ phase: Double) -> Double {
        sin(phase) + sin(3 * phase) / 3 + sin(5 * phase) / 5
    }

    private static func wav(_ samples: [Int16]) -> Data {
        let byteCount = UInt32(samples.count * 2)
        var data = Data()
        data.append(contentsOf: Array("RIFF".utf8))
        appendLE(UInt32(36) + byteCount, to: &data)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8))
        appendLE(UInt32(16), to: &data)                 // fmt chunk size
        appendLE(UInt16(1), to: &data)                  // PCM
        appendLE(UInt16(1), to: &data)                  // mono
        appendLE(UInt32(sampleRate), to: &data)         // sample rate
        appendLE(UInt32(sampleRate) * 2, to: &data)     // byte rate
        appendLE(UInt16(2), to: &data)                  // block align
        appendLE(UInt16(16), to: &data)                 // bits per sample
        data.append(contentsOf: Array("data".utf8))
        appendLE(byteCount, to: &data)
        for sample in samples {
            appendLE(sample, to: &data)
        }
        return data
    }

    private static func appendLE<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
    }
}
