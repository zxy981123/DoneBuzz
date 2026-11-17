import Foundation
import SwiftData

@Model
final class Todo {
    var title: String
    /// Optional time estimate chosen when the item is created.
    var durationMinutes: Int?
    var createdAt: Date
    /// nil while the item is still active.
    var completedAt: Date?

    init(title: String, durationMinutes: Int? = nil, createdAt: Date = .now) {
        self.title = title
        self.durationMinutes = durationMinutes
        self.createdAt = createdAt
        self.completedAt = nil
    }
}

enum DurationOption {
    /// The quick-pick durations offered when adding an item, in minutes.
    static let all: [Int] = [5, 15, 25, 45, 60]
    /// One pomodoro.
    static let pomodoro = 25

    static func label(for minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) 分钟"
        }
        let hours = minutes / 60
        let rest = minutes % 60
        let hourText = "\(hours) 小时"
        return rest == 0 ? hourText : "\(hourText) \(rest) 分钟"
    }

    /// Label for the quick-pick chips; the pomodoro length gets a tomato.
    static func chipLabel(for minutes: Int) -> String {
        minutes == pomodoro ? "🍅 " + label(for: minutes) : label(for: minutes)
    }
}
