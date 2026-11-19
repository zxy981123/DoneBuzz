import Foundation

struct StreakInfo: Equatable {
    /// Days with something finished in the current run (a single rest day inside it is fine).
    var current: Int
    /// The longest such run on record.
    var best: Int
    var doneToday: Bool

    static let empty = StreakInfo(current: 0, best: 0, doneToday: false)
}

/// A forgiving streak: it counts days on which something was finished, and one day off in a row
/// does not break it. Two empty days in a row do.
enum Streak {
    static func compute(completionDates: [Date], now: Date = .now, calendar: Calendar = .current) -> StreakInfo {
        let days = Set(completionDates.map { calendar.startOfDay(for: $0) })
        guard let oldest = days.min() else { return .empty }

        let today = calendar.startOfDay(for: now)
        let doneToday = days.contains(today)

        // Current run. Today does not count against you until it is over, so start from yesterday.
        var current = doneToday ? 1 : 0
        var missedInARow = 0
        var cursor = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        while missedInARow < 2, cursor >= oldest {
            if days.contains(cursor) {
                current += 1
                missedInARow = 0
            } else {
                missedInARow += 1
            }
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? oldest.addingTimeInterval(-1)
        }

        // Longest run: consecutive active days at most two days apart.
        var best = 0
        var run = 0
        var previous: Date?
        for day in days.sorted() {
            if let previous, let gap = calendar.dateComponents([.day], from: previous, to: day).day, gap <= 2 {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            previous = day
        }

        return StreakInfo(current: current, best: max(best, current), doneToday: doneToday)
    }
}
