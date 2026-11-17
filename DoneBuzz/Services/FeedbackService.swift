import AVFoundation
import UIKit

/// The "reward" fired when an item is completed: a haptic thump + success buzz and a short chime.
/// The chime is synthesized in code, so the project needs no audio asset.
final class FeedbackService {
    static let shared = FeedbackService()

    private let impact = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private var player: AVAudioPlayer?

    private init() {
        // .ambient respects the silent switch and does not interrupt music.
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        player = try? AVAudioPlayer(data: Self.makeChime(), fileTypeHint: AVFileType.wav.rawValue)
        player?.prepareToPlay()
    }

    /// Warms up the Taptic Engine so the first buzz has no delay.
    func prepare() {
        impact.prepare()
        notification.prepare()
    }

    func taskCompleted() {
        impact.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [notification] in
            notification.notificationOccurred(.success)
        }
        player?.currentTime = 0
        player?.play()
    }

    // MARK: - Chime synthesis

    /// A two-note rising "ding" (A5 -> E6) as 16-bit mono WAV data.
    private static func makeChime() -> Data {
        let sampleRate: Double = 44_100
        let duration: Double = 0.7
        let count = Int(sampleRate * duration)
        let notes: [(freq: Double, start: Double)] = [(880.0, 0.0), (1318.51, 0.09)]
        let twoPi = 2.0 * Double.pi

        var samples = [Int16](repeating: 0, count: count)
        for i in 0..<count {
            let t = Double(i) / sampleRate
            var value: Double = 0
            for note in notes where t >= note.start {
                let local = t - note.start
                let attack = min(local / 0.005, 1.0)
                let envelope = attack * exp(-local * 7.0)
                let fundamental = sin(twoPi * note.freq * local)
                let overtone = 0.3 * sin(twoPi * note.freq * 2.0 * local)
                value += envelope * (fundamental + overtone)
            }
            let clamped = max(-1.0, min(1.0, value * 0.35))
            samples[i] = Int16(clamped * Double(Int16.max))
        }

        let byteCount = UInt32(count * 2)
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
