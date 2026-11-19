import SwiftUI
import WidgetKit

struct TodayEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        // The widget gallery shows sample data until the app has written something real.
        let snapshot = context.isPreview ? (WidgetSnapshot.load() ?? .placeholder) : current(at: .now)
        completion(TodayEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let calendar = Calendar.current
        let now = Date.now
        let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now.addingTimeInterval(86_400)
        var dates = [now]
        // The evening streak nudge, then the new day.
        if let evening = calendar.date(bySettingHour: WidgetMood.eveningHour, minute: 0, second: 0, of: now), evening > now {
            dates.append(evening)
        }
        dates.append(midnight)
        let entries = dates.map { TodayEntry(date: $0, snapshot: current(at: $0)) }
        // The app asks for a reload whenever the list changes; otherwise refresh after midnight.
        completion(Timeline(entries: entries, policy: .after(midnight.addingTimeInterval(60))))
    }

    private func current(at date: Date) -> WidgetSnapshot {
        guard let saved = WidgetSnapshot.load() else {
            let isChinese = Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
            return WidgetSnapshot(openTitles: [], done: 0, streak: 0, lastActiveDay: nil, isChinese: isChinese, now: date)
        }
        return saved.asOf(date)
    }
}

struct TodayWidget: Widget {
    private var copy: WidgetCopy {
        WidgetCopy(isChinese: WidgetSnapshot.load()?.isChinese ?? (Locale.preferredLanguages.first?.hasPrefix("zh") ?? true))
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSnapshot.widgetKind, provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
        }
        .configurationDisplayName(copy.displayName)
        .description(copy.description)
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct TodayWidgetView: View {
    let entry: TodayEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular: CircularView(snapshot: entry.snapshot)
        case .accessoryRectangular: RectangularView(snapshot: entry.snapshot)
        case .accessoryInline: InlineView(snapshot: entry.snapshot)
        case .systemMedium: MediumView(entry: entry)
        default: SmallView(entry: entry)
        }
    }
}

// MARK: Home screen

/// Sky with a strip of grass along the bottom, like the app.
private struct WidgetSky: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.sky
            VStack(spacing: 0) {
                Theme.grass.frame(height: 8)
                Theme.dirt.frame(height: 20)
            }
            .overlay(alignment: .top) { Theme.ink.frame(height: 2) }
        }
    }
}

private struct StreakPill: View {
    let snapshot: WidgetSnapshot
    let copy: WidgetCopy

    var body: some View {
        HStack(spacing: 3) {
            Text("🔥")
                .font(.system(size: 14))
                .saturation(snapshot.streak > 0 ? 1 : 0)
            Text("\(snapshot.streak)")
                .font(.system(.subheadline, design: .rounded, weight: .black))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.white, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.ink, lineWidth: 2))
        .accessibilityLabel(copy.isChinese ? "连续 \(snapshot.streak) 天" : "\(snapshot.streak) day streak")
    }
}

private struct CoinPill: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(spacing: 4) {
            PixelSprite.coin.frame(width: 14, height: 14)
            Text("\(snapshot.done)/\(snapshot.total)")
                .font(.system(.subheadline, design: .rounded, weight: .black))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.white, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.ink, lineWidth: 2))
    }
}

/// What the cat says, in a speech bubble.
private struct Bubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .heavy, design: .rounded))
            .foregroundStyle(Theme.ink)
            .lineLimit(2)
            .minimumScaleFactor(0.75)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.ink, lineWidth: 2))
    }
}

/// A chunky progress bar; gold fills as items are finished.
private struct ProgressStrip: View {
    let done: Int
    let total: Int

    var body: some View {
        GeometryReader { proxy in
            let fraction = total > 0 ? min(1, CGFloat(done) / CGFloat(total)) : 0
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white)
                Capsule().fill(Theme.gold)
                    .frame(width: max(fraction > 0 ? 10 : 0, proxy.size.width * fraction))
                Capsule().strokeBorder(Theme.ink, lineWidth: 2)
            }
        }
        .frame(height: 12)
        .accessibilityHidden(true)
    }
}

/// The cat, which turns happy (and finds a coin) once the day is done.
private struct WidgetCat: View {
    let mood: WidgetMood
    let size: CGFloat

    var body: some View {
        PixelSprite.cat
            .frame(width: size, height: size)
            .overlay(alignment: .topTrailing) {
                if mood == .allDone {
                    PixelSprite.coin
                        .frame(width: size * 0.36, height: size * 0.36)
                        .offset(x: size * 0.2, y: -size * 0.15)
                }
            }
            .accessibilityHidden(true)
    }
}

private struct SmallView: View {
    let entry: TodayEntry

    var body: some View {
        let snapshot = entry.snapshot
        let copy = WidgetCopy(isChinese: snapshot.isChinese)
        let mood = WidgetMood(snapshot, now: entry.date)
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                StreakPill(snapshot: snapshot, copy: copy)
                Spacer(minLength: 0)
                if snapshot.total > 0 { CoinPill(snapshot: snapshot) }
            }
            Bubble(text: copy.line(for: mood))
            Spacer(minLength: 0)
            HStack(alignment: .bottom) {
                WidgetCat(mood: mood, size: 40)
                if snapshot.total > 0 {
                    ProgressStrip(done: snapshot.done, total: snapshot.total)
                        .padding(.bottom, 8)
                }
            }
            .padding(.bottom, 6)
        }
        .containerBackground(for: .widget) { WidgetSky() }
        .widgetURL(snapshot.total == 0 ? WidgetSnapshot.addURL : nil)
    }
}

private struct MediumView: View {
    let entry: TodayEntry

    var body: some View {
        let snapshot = entry.snapshot
        let copy = WidgetCopy(isChinese: snapshot.isChinese)
        let mood = WidgetMood(snapshot, now: entry.date)
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    StreakPill(snapshot: snapshot, copy: copy)
                    if snapshot.total > 0 { CoinPill(snapshot: snapshot) }
                }
                Bubble(text: copy.line(for: mood))
                Spacer(minLength: 0)
                HStack(alignment: .bottom, spacing: 8) {
                    WidgetCat(mood: mood, size: 44)
                    if snapshot.total > 0 {
                        ProgressStrip(done: snapshot.done, total: snapshot.total)
                            .padding(.bottom, 8)
                    }
                }
                .padding(.bottom, 6)
            }
            .frame(width: 138, alignment: .leading)

            nextUp(snapshot: snapshot, copy: copy)
        }
        .containerBackground(for: .widget) { WidgetSky() }
    }

    private func nextUp(snapshot: WidgetSnapshot, copy: WidgetCopy) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(copy.nextUp)
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(Theme.muted)
                Spacer(minLength: 0)
                Link(destination: WidgetSnapshot.addURL) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 26, height: 26)
                        .background(Theme.gold, in: Circle())
                        .overlay(Circle().strokeBorder(Theme.ink, lineWidth: 2))
                }
                .accessibilityLabel(copy.add)
            }
            if snapshot.openTitles.isEmpty {
                Text(snapshot.total > 0 ? copy.restTime : copy.nothingOpen)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.ink)
            } else {
                ForEach(Array(snapshot.openTitles.enumerated()), id: \.offset) { _, title in
                    HStack(spacing: 6) {
                        Circle().strokeBorder(Theme.ink, lineWidth: 2).frame(width: 12, height: 12)
                        Text(title)
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                    }
                }
                if snapshot.openCount > snapshot.openTitles.count {
                    Text(copy.more(snapshot.openCount - snapshot.openTitles.count))
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.muted)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.ink, lineWidth: 2))
        .padding(.bottom, 22)
    }
}

// MARK: Lock Screen

private struct CircularView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        Gauge(value: Double(snapshot.done), in: 0...Double(max(snapshot.total, 1))) {
            Text("🔥")
        } currentValueLabel: {
            Text("\(snapshot.done)/\(snapshot.total)")
                .font(.system(.body, design: .rounded, weight: .black))
                .minimumScaleFactor(0.6)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
        .containerBackground(for: .widget) { AccessoryWidgetBackground() }
    }
}

private struct RectangularView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        let copy = WidgetCopy(isChinese: snapshot.isChinese)
        VStack(alignment: .leading, spacing: 2) {
            Text(copy.inline(done: snapshot.done, total: snapshot.total, streak: snapshot.streak))
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .widgetAccentable()
            Text(snapshot.openTitles.first ?? copy.line(for: WidgetMood(snapshot)))
                .font(.system(.body, design: .rounded, weight: .semibold))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.clear }
    }
}

private struct InlineView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        let copy = WidgetCopy(isChinese: snapshot.isChinese)
        Text(copy.inline(done: snapshot.done, total: snapshot.total, streak: snapshot.streak))
            .containerBackground(for: .widget) { Color.clear }
    }
}
