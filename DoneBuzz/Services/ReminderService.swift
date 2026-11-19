import Foundation
import UserNotifications

enum ReminderAccess: Equatable {
    case allowed, denied, notAsked
}

/// The slice of the notification centre the reminders need, so tests can stand in for it.
protocol NotificationCenterProviding {
    func accessStatus() async -> ReminderAccess
    func requestAccess() async -> Bool
    func schedule(_ requests: [UNNotificationRequest]) async
    func cancel(identifiers: [String])
}

struct SystemNotificationCenter: NotificationCenterProviding {
    private var center: UNUserNotificationCenter { .current() }

    func accessStatus() async -> ReminderAccess {
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral: return .allowed
        case .notDetermined: return .notAsked
        default: return .denied
        }
    }

    func requestAccess() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func schedule(_ requests: [UNNotificationRequest]) async {
        for request in requests {
            try? await center.add(request)
        }
    }

    func cancel(identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

/// One gentle nudge a day at a time of the user's choosing. Seven repeating weekly notifications
/// (one per weekday) so the wording can vary through the week.
struct ReminderService {
    static let identifiers = (1...7).map { "donebuzz.daily.\($0)" }
    /// Nine in the morning.
    static let defaultMinutes = 9 * 60

    var center: NotificationCenterProviding = SystemNotificationCenter()

    enum EnableResult: Equatable {
        case enabled, denied
    }

    func requests(minutes: Int, strings: Strings) -> [UNNotificationRequest] {
        let clamped = min(max(minutes, 0), 24 * 60 - 1)
        return (1...7).map { weekday in
            let content = UNMutableNotificationContent()
            content.title = "DoneBuzz"
            content.body = strings.reminderMessage(forWeekday: weekday)
            content.sound = .default

            var when = DateComponents()
            when.weekday = weekday
            when.hour = clamped / 60
            when.minute = clamped % 60
            let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
            return UNNotificationRequest(identifier: "donebuzz.daily.\(weekday)", content: content, trigger: trigger)
        }
    }

    /// Asks for permission the first time, then schedules the week.
    func enable(minutes: Int, strings: Strings) async -> EnableResult {
        var access = await center.accessStatus()
        if access == .notAsked {
            access = await center.requestAccess() ? .allowed : .denied
        }
        guard access == .allowed else { return .denied }
        await apply(minutes: minutes, strings: strings)
        return .enabled
    }

    func disable() {
        center.cancel(identifiers: Self.identifiers)
    }

    /// Re-applies the saved choice (new time, new language, or after a relaunch).
    /// Returns whether reminders are still on; false means permission has since been taken away.
    func sync(enabled: Bool, minutes: Int, strings: Strings) async -> Bool {
        guard enabled else {
            disable()
            return false
        }
        guard await center.accessStatus() == .allowed else {
            disable()
            return false
        }
        await apply(minutes: minutes, strings: strings)
        return true
    }

    private func apply(minutes: Int, strings: Strings) async {
        center.cancel(identifiers: Self.identifiers)
        await center.schedule(requests(minutes: minutes, strings: strings))
    }
}
