import SwiftUI

/// Ribbons and dots that rain down from the top of the screen. Each increase of `bursts` plays one shower.
struct ConfettiView: View {
    let bursts: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startedAt: Date?
    @State private var pieces: [Piece] = []

    /// How long one shower stays on screen, in seconds.
    private static let duration: Double = 4.5

    private static let colors: [Color] = [
        Color(red: 0.16, green: 0.50, blue: 0.96),  // blue
        Color(red: 0.95, green: 0.49, blue: 0.10),  // orange
        Color(red: 0.13, green: 0.70, blue: 0.45),  // green
        Color(red: 0.98, green: 0.78, blue: 0.18),  // yellow
        Color(red: 0.96, green: 0.36, blue: 0.56),  // pink
        Color(red: 0.58, green: 0.40, blue: 0.93),  // purple
    ]

    var body: some View {
        Group {
            if let startedAt {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let elapsed = timeline.date.timeIntervalSince(startedAt)
                        for piece in pieces {
                            draw(piece, at: elapsed, in: size, context: &context)
                        }
                    }
                }
            }
        }
        .onChange(of: bursts) {
            // People who turn on Reduce Motion still get the green tick, buzz and chime.
            guard !reduceMotion else { return }
            let started = Date()
            pieces = (0..<90).map { _ in Piece.random(colors: Self.colors) }
            startedAt = started
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.duration) {
                // A newer shower may have started meanwhile; only clear our own.
                if startedAt == started { startedAt = nil }
            }
        }
    }

    private func draw(_ piece: Piece, at elapsed: Double, in size: CGSize, context: inout GraphicsContext) {
        let t = elapsed - piece.delay
        guard t > 0 else { return }

        let y = -30 + piece.speed * t + 45 * t * t
        guard y < size.height + 40 else { return }
        let x = piece.x * size.width + piece.sway * sin(piece.swayRate * t + piece.phase)

        // Fade out over the last second.
        let fade = min(1, max(0, Self.duration - elapsed))

        var layer = context
        layer.opacity = fade
        layer.translateBy(x: x, y: y)
        layer.rotate(by: .radians(piece.spin * t + piece.phase))
        // Squashing one axis back and forth makes a flat ribbon look like it tumbles.
        layer.scaleBy(x: 1, y: max(0.15, abs(cos(piece.flip * t + piece.phase))))

        let rect = CGRect(
            x: -piece.size.width / 2,
            y: -piece.size.height / 2,
            width: piece.size.width,
            height: piece.size.height
        )
        let path = piece.isDot
            ? Path(ellipseIn: rect)
            : Path(roundedRect: rect, cornerRadius: 2)
        layer.fill(path, with: .color(piece.color))
    }

    private struct Piece {
        var x: Double            // 0...1 across the screen
        var delay: Double        // seconds before it drops
        var speed: Double        // points per second
        var sway: Double
        var swayRate: Double
        var phase: Double
        var spin: Double
        var flip: Double
        var size: CGSize
        var isDot: Bool
        var color: Color

        static func random(colors: [Color]) -> Piece {
            let kind = Int.random(in: 0..<10)
            let size: CGSize
            switch kind {
            case 0..<6: size = CGSize(width: 9, height: 24)     // ribbon
            case 6..<8: size = CGSize(width: 11, height: 11)    // square
            default: size = CGSize(width: 10, height: 10)       // dot
            }
            return Piece(
                x: .random(in: 0...1),
                delay: .random(in: 0...0.9),
                speed: .random(in: 150...300),
                sway: .random(in: 10...34),
                swayRate: .random(in: 2...5),
                phase: .random(in: 0...(2 * .pi)),
                spin: .random(in: -4...4),
                flip: .random(in: 3...8),
                size: size,
                isDot: kind >= 8,
                color: colors.randomElement() ?? .blue
            )
        }
    }
}
