import SwiftUI

/// The little side-scrolling scene at the top of the To-do screen. The cat walks toward the
/// finish flag as the day's items get done, and hops to knock out a coin each time one is ticked off.
struct StageView: View {
    let done: Int
    let total: Int
    /// Bumped once per completion; every bump plays one hop and one coin.
    let hops: Int

    @Environment(\.strings) private var s
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private static let height: CGFloat = 156
    /// Shorter at large text sizes so the list keeps some room.
    private var stageHeight: CGFloat { dynamicTypeSize >= .xxxLarge ? 110 : 156 }
    private static let groundHeight: CGFloat = 26
    private static let sprite: CGFloat = 48

    private var progress: CGFloat {
        total == 0 ? 0 : CGFloat(done) / CGFloat(total)
    }

    /// With Reduce Motion on, the cat stays put (the coin counter, buzz and sound still fire).
    private var hopTrigger: Int { reduceMotion ? 0 : hops }

    var body: some View {
        GeometryReader { proxy in
            // Room to walk: from the left edge to just before the flag.
            let travel = max(0, proxy.size.width - Self.sprite - 16 - 64)
            ZStack(alignment: .bottomLeading) {
                scenery
                runner
                    .offset(x: 16 + travel * progress, y: -Self.groundHeight)
                    // Starts walking once the hop has landed.
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.6).delay(0.7), value: progress)
            }
        }
        .frame(height: stageHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(s.stageCaption(done: done, total: total))
    }

    // MARK: - Scenery

    private var scenery: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        return ZStack(alignment: .bottomLeading) {
            Theme.skyLight
            Ellipse()
                .fill(Theme.hillFar)
                .frame(width: 170, height: 90)
                .offset(x: -30, y: -10)
            Ellipse()
                .fill(Theme.hillFarLight)
                .frame(width: 200, height: 70)
                .offset(x: 150, y: -10)
            VStack(spacing: 0) {
                Theme.grassDark.frame(height: 6)
                Theme.dirt.frame(height: Self.groundHeight - 6)
            }
            ForEach([40, 120, 220], id: \.self) { x in
                Theme.dirtDark
                    .frame(width: 4, height: 4)
                    .offset(x: CGFloat(x), y: -CGFloat(5 + x % 7))
            }
        }
        .overlay(alignment: .bottomTrailing) { flag }
        .overlay(alignment: .topLeading) {
            Text(s.stageCaption(done: done, total: total))
                .font(Theme.hint)
                .foregroundStyle(Theme.ink)
                .padding(.leading, 14)
                .padding(.top, 12)
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(Theme.ink, lineWidth: Theme.outline))
    }

    private var flag: some View {
        ZStack(alignment: .topLeading) {
            Theme.ink.frame(width: 4, height: 76)
            CheckeredFlag()
                .offset(x: 4, y: 2)
        }
        .frame(width: 32, height: 76, alignment: .topLeading)
        .padding(.trailing, 14)
        .padding(.bottom, Self.groundHeight)
    }

    // MARK: - The cat, its coin and the "+1"

    private var runner: some View {
        ZStack(alignment: .bottomLeading) {
            PixelSprite.coin
                .frame(width: 28, height: 28)
                .keyframeAnimator(initialValue: CoinPop(), trigger: hopTrigger) { content, pop in
                    content
                        .rotation3DEffect(.degrees(pop.spin), axis: (x: 0, y: 1, z: 0))
                        .offset(x: 10, y: pop.y)
                        .opacity(pop.opacity)
                } keyframes: { _ in
                    // Waits for the cat to reach the top of its hop, then shoots up spinning.
                    KeyframeTrack(\.y) {
                        LinearKeyframe(-50, duration: 0.18)
                        CubicKeyframe(-112, duration: 0.42)
                        LinearKeyframe(-128, duration: 0.36)
                    }
                    KeyframeTrack(\.spin) {
                        LinearKeyframe(0, duration: 0.18)
                        LinearKeyframe(1080, duration: 0.78)
                    }
                    KeyframeTrack(\.opacity) {
                        LinearKeyframe(0, duration: 0.18)
                        LinearKeyframe(1, duration: 0.08)
                        LinearKeyframe(1, duration: 0.4)
                        LinearKeyframe(0, duration: 0.3)
                    }
                }

            Text("+1")
                .font(Theme.pixelNumber)
                .foregroundStyle(.white)
                .shadow(color: Theme.ink, radius: 0, x: 2, y: 2)
                .keyframeAnimator(initialValue: CoinPop(), trigger: hopTrigger) { content, pop in
                    content
                        .offset(x: 46, y: pop.y)
                        .opacity(pop.opacity)
                } keyframes: { _ in
                    KeyframeTrack(\.y) {
                        LinearKeyframe(-92, duration: 0.32)
                        LinearKeyframe(-128, duration: 0.9)
                    }
                    KeyframeTrack(\.opacity) {
                        LinearKeyframe(0, duration: 0.32)
                        LinearKeyframe(1, duration: 0.15)
                        LinearKeyframe(0, duration: 0.75)
                    }
                }

            PixelSprite.cat
                .frame(width: Self.sprite, height: Self.sprite)
                .keyframeAnimator(initialValue: Hop(), trigger: hopTrigger) { content, hop in
                    content
                        .scaleEffect(x: hop.scaleX, y: hop.scaleY, anchor: .bottom)
                        .rotationEffect(.degrees(hop.tilt), anchor: .bottom)
                        .offset(y: hop.y)
                } keyframes: { _ in
                    // Crouch, jump, hang at the top, land with a squash, settle.
                    KeyframeTrack(\.y) {
                        LinearKeyframe(0, duration: 0.08)
                        CubicKeyframe(-50, duration: 0.2)
                        LinearKeyframe(-50, duration: 0.1)
                        CubicKeyframe(0, duration: 0.17)
                        LinearKeyframe(0, duration: 0.07)
                    }
                    KeyframeTrack(\.scaleX) {
                        CubicKeyframe(1.16, duration: 0.08)
                        CubicKeyframe(0.9, duration: 0.2)
                        CubicKeyframe(1, duration: 0.1)
                        CubicKeyframe(1.14, duration: 0.17)
                        SpringKeyframe(1, duration: 0.15)
                    }
                    KeyframeTrack(\.scaleY) {
                        CubicKeyframe(0.8, duration: 0.08)
                        CubicKeyframe(1.1, duration: 0.2)
                        CubicKeyframe(1, duration: 0.1)
                        CubicKeyframe(0.86, duration: 0.17)
                        SpringKeyframe(1, duration: 0.15)
                    }
                    KeyframeTrack(\.tilt) {
                        LinearKeyframe(0, duration: 0.08)
                        CubicKeyframe(-8, duration: 0.2)
                        CubicKeyframe(0, duration: 0.27)
                    }
                }
        }
        .frame(width: Self.sprite, height: Self.sprite, alignment: .bottomLeading)
    }

    private struct Hop {
        var y: CGFloat = 0
        var scaleX: CGFloat = 1
        var scaleY: CGFloat = 1
        var tilt: Double = 0
    }
}
