import SwiftUI

enum Theme {
    // Calm sky-blue page, plain white cards, and one job per colour:
    // blue = things you can tap, orange = time, green = done.
    static let accent = Color(red: 0.16, green: 0.50, blue: 0.96)
    static let highlight = Color(red: 0.95, green: 0.49, blue: 0.10)
    static let success = Color(red: 0.13, green: 0.70, blue: 0.45)
    static let background = dynamic(
        light: UIColor(red: 0.90, green: 0.95, blue: 1.00, alpha: 1),
        dark: UIColor(red: 0.06, green: 0.09, blue: 0.14, alpha: 1)
    )
    static let card = dynamic(
        light: .white,
        dark: UIColor(red: 0.12, green: 0.16, blue: 0.22, alpha: 1)
    )
    static let cardRadius: CGFloat = 22

    // Easy-to-read type: heavy rounded letters, large sizes, and loose spacing, so each line
    // can be taken in at a glance. Built on text styles, so it still scales with the system
    // text-size setting.
    static let itemTitle = Font.system(.title2, design: .rounded, weight: .heavy)
    static let sheetTitle = Font.system(.title, design: .rounded, weight: .heavy)
    static let progress = Font.system(.title3, design: .rounded, weight: .heavy)
    static let historyTitle = Font.system(.title3, design: .rounded, weight: .bold)
    static let label = Font.system(.headline, design: .rounded, weight: .bold)
    static let hint = Font.system(.subheadline, design: .rounded, weight: .semibold)
    static let button = Font.system(.title3, design: .rounded, weight: .heavy)
    /// Extra room between letters and between lines of the main item text.
    static let titleTracking: CGFloat = 0.8
    static let titleLineSpacing: CGFloat = 7

    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

/// Horizontal wiggle. Animate `animatableData` from 0 to 1 to play it once.
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 9
    var shakes: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = amount * sin(animatableData * .pi * 2 * shakes)
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

struct DurationBadge: View {
    let minutes: Int

    var body: some View {
        Label(DurationOption.label(for: minutes), systemImage: "clock")
            .font(Theme.label)
            .foregroundStyle(Theme.highlight)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.highlight.opacity(0.15), in: Capsule())
    }
}
