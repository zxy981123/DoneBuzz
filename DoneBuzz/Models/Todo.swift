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
    /// Their labels come from `Strings.duration(_:)` so they follow the chosen language.
    static let all: [Int] = [5, 15, 25, 45, 60]
    /// One pomodoro.
    static let pomodoro = 25
}
