import ActivityKit
import SwiftUI
import WidgetKit

@main
struct DoneBuzzWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FocusLiveActivity()
    }
}

private enum Palette {
    static let ink = Color(red: 0x14 / 255, green: 0x21 / 255, blue: 0x3D / 255)
    static let gold = Color(red: 0xF5 / 255, green: 0xB3 / 255, blue: 0x01 / 255)
    static let goldLight = Color(red: 0xFF / 255, green: 0xE2 / 255, blue: 0x7A / 255)
}

struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            LockScreenFocusView(context: context)
                .activityBackgroundTint(Palette.ink)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Palette.gold)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Countdown(context: context)
                        .font(.title2.weight(.heavy).monospacedDigit())
                        .foregroundStyle(Palette.goldLight)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.attributes.focusingLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.7))
                        Text(context.attributes.title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    FocusProgress(context: context)
                        .padding(.horizontal, 4)
                        .padding(.top, 6)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .font(.body.weight(.bold))
                    .foregroundStyle(Palette.gold)
            } compactTrailing: {
                Countdown(context: context)
                    .font(.body.weight(.bold).monospacedDigit())
                    .foregroundStyle(Palette.goldLight)
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: "timer")
                    .font(.body.weight(.bold))
                    .foregroundStyle(Palette.gold)
            }
            .keylineTint(Palette.gold)
        }
    }
}

/// Counts down by itself, with no app updates needed. Shows "Time's up" once the timer has ended.
private struct Countdown: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    var body: some View {
        let state = context.state
        if context.isStale || state.endDate <= .now {
            Text(context.attributes.timesUpLabel)
        } else {
            Text(timerInterval: Date.now...max(state.endDate, Date.now), countsDown: true)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct FocusProgress: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    var body: some View {
        let state = context.state
        let start = min(state.startDate, state.endDate)
        ProgressView(timerInterval: start...state.endDate, countsDown: true) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .tint(Palette.gold)
    }
}

private struct LockScreenFocusView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "timer")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 40, height: 40)
                    .background(Palette.gold, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.focusingLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(context.attributes.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Countdown(context: context)
                    .font(.title.weight(.heavy).monospacedDigit())
                    .foregroundStyle(Palette.goldLight)
            }
            FocusProgress(context: context)
        }
        .padding(16)
    }
}
