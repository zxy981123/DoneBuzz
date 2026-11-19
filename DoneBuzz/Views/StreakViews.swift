import SwiftUI

/// A small flame-and-number pill for the To-do header.
struct StreakBadge: View {
    let info: StreakInfo
    @Environment(\.strings) private var s

    var body: some View {
        HStack(spacing: 4) {
            Text("🔥")
            Text("\(info.current)")
                .font(Theme.pixelNumber)
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(Theme.goldLight, in: Capsule())
        .gameOutline(Capsule(), lineWidth: 2.5, drop: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(s.streakDays(info.current)). \(s.streakRestHint)")
    }
}

/// The streak line at the top of the Done screen.
struct StreakBanner: View {
    let info: StreakInfo
    @Environment(\.strings) private var s

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if info.current > 0 {
                HStack(spacing: 8) {
                    Text("🔥")
                    Text(s.streakDays(info.current))
                        .font(Theme.progress)
                        .foregroundStyle(Theme.ink)
                    Text("·")
                        .foregroundStyle(Theme.muted)
                    Text(s.bestStreak(info.best))
                        .font(Theme.label)
                        .foregroundStyle(Theme.muted)
                }
                Text(s.streakRestHint)
                    .font(Theme.hint)
                    .foregroundStyle(Theme.muted)
            } else {
                Text(s.streakStart)
                    .font(Theme.hint)
                    .foregroundStyle(Theme.muted)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
