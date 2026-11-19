import Foundation

/// How far the cat has walked toward the flag today, from 0 (start) to 1 (flag).
///
/// The cat only ever walks backwards when you un-tick an item. Adding or deleting items never moves it.
/// Each finished item covers an equal share of the road that is left, so the cat still reaches the flag
/// exactly when the last open item is ticked off, however many items were added along the way.
struct CatProgress: Codable, Equatable {
    /// Start of the day this belongs to; a new day starts the cat from scratch.
    var day: Date
    var position: Double
    /// The counts `position` was last worked out for, so the next change can be told apart.
    var done: Int
    var total: Int

    static func fresh(done: Int, total: Int, day: Date) -> CatProgress {
        CatProgress(day: day, position: ratio(done: done, total: total), done: done, total: total)
    }

    static func ratio(done: Int, total: Int) -> Double {
        total <= 0 ? 0 : min(1, max(0, Double(done) / Double(total)))
    }

    /// Brings the position up to date with the day's current counts.
    mutating func update(done: Int, total: Int, now: Date = .now, calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        guard day == today else {
            self = .fresh(done: done, total: total, day: today)
            return
        }

        let doneChange = done - self.done
        let totalChange = total - self.total
        guard doneChange != 0 || totalChange != 0 else { return }

        let open = total - done
        let openBefore = self.total - self.done
        var p = position

        if doneChange == 0 {
            // Items were added, or open items deleted: nothing was finished, so the cat stays put.
        } else if doneChange == 1 && totalChange == 0 {
            // One item finished: walk an equal share of the road that is left.
            p += (1 - p) / Double(max(openBefore, 1))
        } else if doneChange == -1 && totalChange == 0 {
            // One item un-ticked: take back exactly that share.
            p = open > 1 ? (p * Double(open) - 1) / Double(open - 1) : Self.ratio(done: done, total: total)
        } else if doneChange < 0 && totalChange == doneChange {
            // Only finished items were deleted: the road ahead is unchanged, so stay put.
        } else {
            // Anything else (several kinds of change at once): fall back to the plain share done.
            p = Self.ratio(done: done, total: total)
        }

        if total <= 0 || done <= 0 {
            p = 0
        } else if open <= 0 {
            p = 1
        }

        position = min(1, max(0, p))
        self.done = done
        self.total = total
    }

    // MARK: Storage

    private static let storageKey = "catProgress"

    static func load(defaults: UserDefaults = .standard, now: Date = .now, calendar: Calendar = .current) -> CatProgress {
        if let data = defaults.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode(CatProgress.self, from: data) {
            return saved
        }
        return .fresh(done: 0, total: 0, day: calendar.startOfDay(for: now))
    }

    func save(defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(self) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
