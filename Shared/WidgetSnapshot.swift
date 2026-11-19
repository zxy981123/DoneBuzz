import Foundation

/// What the home screen widget shows. The app writes it to the shared App Group whenever the
/// to-do list changes; the widget only reads it, so it never touches the database.
struct WidgetSnapshot: Codable, Equatable {
    /// Start of the day the snapshot was taken.
    var day: Date
    var done: Int
    var total: Int
    /// The first few open items, in the order the list shows them.
    var openTitles: [String]
    /// How many items are still open (may be more than `openTitles`).
    var openCount: Int
    var streak: Int
    /// Start of the most recent day with something finished, if any.
    var lastActiveDay: Date?
    var isChinese: Bool

    static let appGroup = "group.com.adhd.DoneBuzz"
    static let storageKey = "widgetSnapshot"
    static let widgetKind = "DoneBuzzToday"
    /// Opens the add sheet when the widget's + is tapped.
    static let addURL = URL(string: "donebuzz://add")!
    static let maxTitles = 3

    static let placeholder = WidgetSnapshot(
        day: Calendar.current.startOfDay(for: .now), done: 2, total: 5,
        openTitles: ["Reply to Sam", "Laundry", "Book dentist"], openCount: 3,
        streak: 4, lastActiveDay: Calendar.current.startOfDay(for: .now), isChinese: false
    )

    init(day: Date, done: Int, total: Int, openTitles: [String], openCount: Int,
         streak: Int, lastActiveDay: Date?, isChinese: Bool) {
        self.day = day
        self.done = done
        self.total = total
        self.openTitles = openTitles
        self.openCount = openCount
        self.streak = streak
        self.lastActiveDay = lastActiveDay
        self.isChinese = isChinese
    }

    /// Builds the snapshot from today's list (newest first, as on screen) and the streak.
    init(openTitles: [String], done: Int, streak: Int, lastActiveDay: Date?, isChinese: Bool,
         now: Date = .now, calendar: Calendar = .current) {
        self.init(
            day: calendar.startOfDay(for: now),
            done: done,
            total: done + openTitles.count,
            openTitles: Array(openTitles.prefix(Self.maxTitles)),
            openCount: openTitles.count,
            streak: streak,
            lastActiveDay: lastActiveDay.map { calendar.startOfDay(for: $0) },
            isChinese: isChinese
        )
    }

    var doneToday: Bool { lastActiveDay == day }

    /// The snapshot as it should read at `now`. After midnight yesterday's finished items drop
    /// off, open ones carry over, and the streak lapses once two whole days pass with nothing done
    /// (the same forgiving rule as the app).
    func asOf(_ now: Date, calendar: Calendar = .current) -> WidgetSnapshot {
        let today = calendar.startOfDay(for: now)
        guard today > day else { return self }
        var copy = self
        copy.day = today
        copy.done = 0
        copy.total = openCount
        if let last = lastActiveDay,
           let gap = calendar.dateComponents([.day], from: last, to: today).day, gap <= 2 {
            copy.streak = streak
        } else {
            copy.streak = 0
        }
        return copy
    }

    // MARK: Storage

    static func load(from defaults: UserDefaults? = UserDefaults(suiteName: appGroup)) -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save(to defaults: UserDefaults? = UserDefaults(suiteName: Self.appGroup)) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults?.set(data, forKey: Self.storageKey)
    }
}

/// The cat's mood on the widget, which picks the line it says.
enum WidgetMood: Equatable {
    /// Nothing on the list.
    case empty
    /// Items waiting, none done yet today.
    case start(left: Int)
    case going(left: Int)
    case allDone
    /// Evening, a streak is running and nothing is done yet today.
    case saveStreak(days: Int)

    /// From this hour on, an unbroken streak with nothing done today gets the gentle nudge.
    static let eveningHour = 18

    init(_ snapshot: WidgetSnapshot, now: Date = .now, calendar: Calendar = .current) {
        let left = snapshot.total - snapshot.done
        if snapshot.total == 0 {
            self = .empty
        } else if left <= 0 {
            self = .allDone
        } else if snapshot.done == 0, snapshot.streak > 0, !snapshot.doneToday,
                  calendar.component(.hour, from: now) >= Self.eveningHour {
            self = .saveStreak(days: snapshot.streak)
        } else if snapshot.done == 0 {
            self = .start(left: left)
        } else {
            self = .going(left: left)
        }
    }
}

/// Widget wording in both languages. Short and kind: the widget nudges, it never scolds.
struct WidgetCopy {
    let isChinese: Bool

    private func pick(_ zh: String, _ en: String) -> String { isChinese ? zh : en }

    func line(for mood: WidgetMood) -> String {
        switch mood {
        case .empty: return pick("加一件小事吧", "Add one tiny thing")
        case .start: return pick("先做一件就好！", "Just start one!")
        case .going(let left): return pick("还剩 \(left) 件，冲！", "\(left) to go, keep rolling!")
        case .allDone: return pick("今天全搞定！🎉", "All done today! 🎉")
        case .saveStreak: return pick("别让火苗熄灭 🔥", "Keep your 🔥 alive!")
        }
    }

    func progress(done: Int, total: Int) -> String { "\(done)/\(total)" }
    var nextUp: String { pick("接下来", "Next up") }
    var nothingOpen: String { pick("还没有待办，点 + 加一件", "Nothing yet. Tap + to add one") }
    var restTime: String { pick("可以休息啦 ☕️", "Time to rest ☕️") }
    func more(_ count: Int) -> String { pick("还有 \(count) 件", "+\(count) more") }
    func streakDays(_ days: Int) -> String { pick("\(days) 天", "\(days)d") }
    var add: String { pick("添加", "Add") }
    var displayName: String { pick("今日进度", "Today") }
    var description: String { pick("小猫陪你看今天的进度和连续天数。", "Your cat, today's progress and your streak.") }
    var lockDescription: String { pick("在锁屏上看今天的进度。", "Today's progress on your Lock Screen.") }
    func inline(done: Int, total: Int, streak: Int) -> String {
        let flame = streak > 0 ? "🔥\(streak) · " : ""
        return flame + pick("完成 \(done)/\(total)", "\(done)/\(total) done")
    }
}
