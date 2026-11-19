import CoreHaptics
import Foundation

/// A haptic pattern described as plain data, so it can be checked in tests and played with Core Haptics.
struct HapticPattern: Equatable {
    struct Tap: Equatable {
        var time: Double
        var intensity: Float
        var sharpness: Float
    }

    /// A continuous buzz that fades from `intensity` to `endIntensity`.
    struct Buzz: Equatable {
        var time: Double
        var duration: Double
        var intensity: Float
        var endIntensity: Float
        var sharpness: Float
    }

    var taps: [Tap]
    var buzzes: [Buzz]

    var duration: Double {
        max(taps.map(\.time).max() ?? 0, buzzes.map { $0.time + $0.duration }.max() ?? 0)
    }

    /// Finishing one item, about half a second. Timed to the sound and the coin pop at 0.22 s.
    static let taskCompleted = HapticPattern(
        taps: [
            Tap(time: 0.00, intensity: 1.0, sharpness: 0.45),  // the press
            Tap(time: 0.09, intensity: 0.55, sharpness: 0.5),
            Tap(time: 0.15, intensity: 0.75, sharpness: 0.7),
            Tap(time: 0.22, intensity: 1.0, sharpness: 0.95), // the coin
            Tap(time: 0.34, intensity: 0.55, sharpness: 0.8),
            Tap(time: 0.44, intensity: 0.35, sharpness: 0.9),
        ],
        buzzes: [
            Buzz(time: 0.0, duration: 0.3, intensity: 0.65, endIntensity: 0.1, sharpness: 0.15),
        ]
    )

    /// Clearing the whole day: a quickening drum-roll that builds into one big hit and a long fade.
    static let dayCleared: HapticPattern = {
        let rollTimes: [Double] = [0, 0.11, 0.2, 0.27, 0.33, 0.38, 0.42, 0.46]
        let roll = rollTimes.enumerated().map { index, time in
            Tap(
                time: time,
                intensity: 0.3 + 0.6 * Float(index) / Float(rollTimes.count - 1),
                sharpness: 0.4 + 0.4 * Float(index) / Float(rollTimes.count - 1)
            )
        }
        return HapticPattern(
            taps: roll + [
                Tap(time: 0.55, intensity: 1.0, sharpness: 0.6),
                Tap(time: 0.75, intensity: 0.6, sharpness: 0.9),
                Tap(time: 0.9, intensity: 0.4, sharpness: 1.0),
            ],
            buzzes: [
                Buzz(time: 0.55, duration: 0.6, intensity: 0.8, endIntensity: 0.0, sharpness: 0.2),
            ]
        )
    }()

    func makePattern() throws -> CHHapticPattern {
        var events: [CHHapticEvent] = taps.map { tap in
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: tap.intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: tap.sharpness),
                ],
                relativeTime: tap.time
            )
        }
        var curves: [CHHapticParameterCurve] = []
        for buzz in buzzes {
            events.append(CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: buzz.intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: buzz.sharpness),
                ],
                relativeTime: buzz.time,
                duration: buzz.duration
            ))
            // The curve scales the buzz's intensity: full at the start, fading to the end value.
            let end = buzz.intensity > 0 ? buzz.endIntensity / buzz.intensity : 0
            curves.append(CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    .init(relativeTime: 0, value: 1),
                    .init(relativeTime: buzz.duration, value: end),
                ],
                relativeTime: buzz.time
            ))
        }
        return try CHHapticPattern(events: events, parameterCurves: curves)
    }
}

/// Plays `HapticPattern`s on the Taptic Engine. Devices without Core Haptics report `false` so the caller
/// can fall back to the simple UIKit feedback generators.
final class HapticPlayer {
    private var engine: CHHapticEngine?
    private let supported = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    func prepare() {
        guard supported else { return }
        _ = startedEngine()
    }

    @discardableResult
    func play(_ pattern: HapticPattern) -> Bool {
        guard supported, let engine = startedEngine() else { return false }
        do {
            try engine.makePlayer(with: pattern.makePattern()).start(atTime: CHHapticTimeImmediate)
            return true
        } catch {
            return false
        }
    }

    private func startedEngine() -> CHHapticEngine? {
        if engine == nil {
            guard let created = try? CHHapticEngine() else { return nil }
            // Haptics only, so the engine never touches the audio session the sounds use.
            created.playsHapticsOnly = true
            created.isAutoShutdownEnabled = true
            created.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            created.stoppedHandler = { [weak self] _ in
                self?.engine = nil
            }
            engine = created
        }
        do {
            try engine?.start()
            return engine
        } catch {
            engine = nil
            return nil
        }
    }
}
