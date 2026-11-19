import SwiftUI

struct DurationBadge: View {
    let minutes: Int

    @Environment(\.strings) private var s

    var body: some View {
        Label(s.duration(minutes), systemImage: "clock")
            .font(Theme.label)
            .foregroundStyle(Theme.tagText)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Theme.tagBackground, in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.ink, lineWidth: 2))
    }
}

/// Today's coins in the top-right corner. Bounces when the count changes, timed to land
/// just as the coin popped by the cat reaches its peak.
struct CoinCounter: View {
    let count: Int

    @Environment(\.strings) private var s

    var body: some View {
        HStack(spacing: 6) {
            PixelSprite.coin
                .frame(width: 24, height: 24)
            Text("×\(count)")
                .font(Theme.pixelNumber)
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
        }
        .padding(.leading, 8)
        .padding(.trailing, 14)
        .padding(.vertical, 6)
        .background(Color.white, in: Capsule())
        .gameOutline(Capsule())
        .keyframeAnimator(initialValue: CGFloat(1), trigger: count) { content, scale in
            content.scaleEffect(scale)
        } keyframes: { _ in
            KeyframeTrack {
                LinearKeyframe(1, duration: 0.55)
                CubicKeyframe(1.25, duration: 0.15)
                SpringKeyframe(1, duration: 0.3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(s.coins(count))
    }
}

/// The sky, rolling hills and clouds behind every screen.
struct SkyBackground: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            ZStack {
                Theme.sky
                PixelSprite.cloud
                    .frame(width: 60, height: 24)
                    .position(x: width * 0.58, y: 74)
                PixelSprite.cloud
                    .frame(width: 44, height: 18)
                    .position(x: 46, y: height * 0.78)
                Ellipse()
                    .fill(Theme.hill)
                    .overlay(Ellipse().strokeBorder(Theme.ink, lineWidth: Theme.outline))
                    .frame(width: 300, height: 260)
                    .position(x: 90, y: height + 20)
                Ellipse()
                    .fill(Theme.grassDark)
                    .overlay(Ellipse().strokeBorder(Theme.ink, lineWidth: Theme.outline))
                    .frame(width: 340, height: 280)
                    .position(x: width - 80, y: height + 30)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
