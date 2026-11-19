import ActivityKit
import Foundation
import Observation
import UserNotifications

extension Todo {
    /// A stable id for a task that the widget extension can carry around without SwiftData.
    var focusKey: String { String(createdAt.timeIntervalSinceReferenceDate) }
}

/// One focus countdown at a time, for a task that has a time estimate. It runs as a Live Activity
/// (Dynamic Island and Lock Screen), and also shows inside the app if Live Activities are switched off.
@MainActor
@Observable
final class FocusTimer {
    static let shared = FocusTimer()

    private(set) var taskKey: String?
    private(set) var endDate: Date?

    private static let endNotificationID = "donebuzz.focus.end"

    func isRunning(for key: String, now: Date = .now) -> Bool {
        guard taskKey == key, let endDate else { return false }
        return endDate > now
    }

    /// Picks up a countdown that was running before the app was closed, and tidies up finished ones.
    func restore(now: Date = .now) async {
        for activity in Activity<FocusActivityAttributes>.activities {
            let end = activity.content.state.endDate
            if end > now, activity.activityState == .active {
                taskKey = activity.attributes.taskKey
                endDate = end
            } else {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    func start(title: String, minutes: Int, key: String, strings: Strings, now: Date = .now) async {
        await stop()
        let end = now.addingTimeInterval(TimeInterval(max(minutes, 1) * 60))
        taskKey = key
        endDate = end

        let attributes = FocusActivityAttributes(
            taskKey: key,
            title: title,
            focusingLabel: strings.focusing,
            timesUpLabel: strings.timesUp
        )
        let content = ActivityContent(
            state: FocusActivityAttributes.ContentState(startDate: now, endDate: end),
            staleDate: end
        )
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            _ = try? Activity.request(attributes: attributes, content: content, pushType: nil)
        }
        await scheduleEndNotification(title: title, at: end, strings: strings)
    }

    func stop() async {
        for activity in Activity<FocusActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.endNotificationID])
        taskKey = nil
        endDate = nil
    }

    /// Stops the countdown if it belongs to this task (it was finished or deleted).
    func stopIfRunning(for key: String) {
        guard taskKey == key else { return }
        Task { await stop() }
    }

    /// Only if notifications are already allowed; starting a timer never asks for permission.
    private func scheduleEndNotification(title: String, at end: Date, strings: Strings) async {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }
        let content = UNMutableNotificationContent()
        content.title = strings.timesUp
        content.body = strings.focusEnded(title)
        content.sound = .default
        let seconds = max(1, end.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: Self.endNotificationID, content: content, trigger: trigger))
    }
}
