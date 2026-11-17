import SwiftUI

enum Theme {
    static let accent = Color(red: 1.0, green: 0.45, blue: 0.33)
    static let success = Color(red: 0.22, green: 0.78, blue: 0.55)
    static let background = Color(.systemGroupedBackground)
    static let card = Color(.secondarySystemGroupedBackground)
    static let cardRadius: CGFloat = 20

    // Chunky rounded type: heavy weights and generous sizes so text is easy to scan.
    // Built on text styles, so it still scales with the system text-size setting.
    static let itemTitle = Font.system(.title2, design: .rounded, weight: .bold)
    static let sheetTitle = Font.system(.title, design: .rounded, weight: .heavy)
    static let historyTitle = Font.system(.title3, design: .rounded, weight: .semibold)
    static let label = Font.system(.subheadline, design: .rounded, weight: .bold)
    static let button = Font.system(.title3, design: .rounded, weight: .bold)
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
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.accent.opacity(0.14), in: Capsule())
    }
}
