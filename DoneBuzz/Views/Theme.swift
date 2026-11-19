import SwiftUI

enum Theme {
    // Side-scroller palette: sky, grass, dirt and gold coins, every shape outlined in dark ink.
    // One job per colour: gold = done / reward, orange = time, ink = text and outlines.
    static let sky = Color(hex: 0x8FD3FF)
    static let skyLight = Color(hex: 0xC8EBFF)
    static let ink = Color(hex: 0x14213D)
    static let muted = Color(hex: 0x4A5568)
    static let gold = Color(hex: 0xF5B301)
    static let goldLight = Color(hex: 0xFFE27A)
    static let grass = Color(hex: 0x5BBF5A)
    static let grassDark = Color(hex: 0x4FAE57)
    static let hill = Color(hex: 0x6CCB6A)
    static let hillFar = Color(hex: 0x9FDB8E)
    static let hillFarLight = Color(hex: 0xB6E6A6)
    static let dirt = Color(hex: 0xC98B4F)
    static let dirtDark = Color(hex: 0x9C6A3C)
    static let card = Color(hex: 0xFFFDF6)
    static let doneCard = Color(hex: 0xFFF6D6)
    static let tagBackground = Color(hex: 0xFFE7C2)
    static let tagText = Color(hex: 0x8A3E00)
    static let recording = Color(hex: 0xE5484D)

    static let cardRadius: CGFloat = 18
    static let outline: CGFloat = 3

    // Easy-to-read type: heavy rounded letters, large sizes, and loose spacing, so each line
    // can be taken in at a glance. Built on text styles, so it still scales with the system
    // text-size setting.
    static let screenTitle = Font.system(.largeTitle, design: .rounded, weight: .black)
    static let itemTitle = Font.system(.title2, design: .rounded, weight: .heavy)
    static let sheetTitle = Font.system(.title, design: .rounded, weight: .heavy)
    static let progress = Font.system(.title3, design: .rounded, weight: .heavy)
    static let historyTitle = Font.system(.title3, design: .rounded, weight: .bold)
    static let label = Font.system(.headline, design: .rounded, weight: .bold)
    static let hint = Font.system(.subheadline, design: .rounded, weight: .semibold)
    static let button = Font.system(.title3, design: .rounded, weight: .heavy)
    /// Chunky numbers for the coin counter and the "+1".
    static let pixelNumber = Font.system(.headline, design: .monospaced, weight: .black)
    /// Extra room between letters and between lines of the main item text.
    static let titleTracking: CGFloat = 0.8
    static let titleLineSpacing: CGFloat = 7
}

extension Color {
    /// `Color(hex: 0x14213D)`
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension View {
    /// The chunky game look: a dark ink outline plus a hard shadow straight below.
    /// Give the view its fill first, e.g. `.background(.white, in: Capsule()).gameOutline(Capsule())`.
    func gameOutline<S: InsettableShape>(_ shape: S, lineWidth: CGFloat = Theme.outline, drop: CGFloat = 4) -> some View {
        self
            .overlay(shape.strokeBorder(Theme.ink, lineWidth: lineWidth))
            .background(shape.fill(Theme.ink).offset(y: drop))
    }
}

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
