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
    static let all: [Int] = [5, 20, 60]

    static func label(for minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        }
        let hours = minutes / 60
        let rest = minutes % 60
        let hourText = hours == 1 ? "1 hour" : "\(hours) hours"
        return rest == 0 ? hourText : "\(hourText) \(rest) min"
    }
}
