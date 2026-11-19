import XCTest
@testable import DoneBuzz

final class WidgetSnapshotTests: XCTestCase {
    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        return c
    }()

    private func date(_ day: Int, _ hour: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
    }

    private func snapshot(open: [String], done: Int, streak: Int = 0, lastActive: Date? = nil, now: Date) -> WidgetSnapshot {
        WidgetSnapshot(openTitles: open, done: done, streak: streak, lastActiveDay: lastActive,
                       isChinese: false, now: now, calendar: calendar)
    }

    func testBuildsTotalsAndCapsTitles() {
        let s = snapshot(open: ["a", "b", "c", "d", "e"], done: 2, now: date(19))
        XCTAssertEqual(s.total, 7)
        XCTAssertEqual(s.openCount, 5)
        XCTAssertEqual(s.openTitles, ["a", "b", "c"])
        XCTAssertEqual(s.day, calendar.startOfDay(for: date(19)))
    }

    func testSameDayIsUnchanged() {
        let s = snapshot(open: ["a"], done: 2, streak: 3, lastActive: date(19), now: date(19))
        XCTAssertEqual(s.asOf(date(19, 23), calendar: calendar), s)
    }

    func testNextDayDropsFinishedItemsAndKeepsOpenOnes() {
        let s = snapshot(open: ["a", "b"], done: 3, streak: 3, lastActive: date(19), now: date(19))
        let next = s.asOf(date(20, 8), calendar: calendar)
        XCTAssertEqual(next.done, 0)
        XCTAssertEqual(next.total, 2)
        XCTAssertEqual(next.openTitles, ["a", "b"])
        XCTAssertEqual(next.streak, 3)
        XCTAssertFalse(next.doneToday)
    }

    func testStreakSurvivesOneRestDay() {
        let s = snapshot(open: [], done: 1, streak: 5, lastActive: date(19), now: date(19))
        XCTAssertEqual(s.asOf(date(21), calendar: calendar).streak, 5)
    }

    func testStreakLapsesAfterTwoEmptyDays() {
        let s = snapshot(open: [], done: 1, streak: 5, lastActive: date(19), now: date(19))
        XCTAssertEqual(s.asOf(date(22), calendar: calendar).streak, 0)
    }

    func testMoods() {
        XCTAssertEqual(WidgetMood(snapshot(open: [], done: 0, now: date(19)), now: date(19), calendar: calendar), .empty)
        XCTAssertEqual(WidgetMood(snapshot(open: ["a", "b"], done: 0, now: date(19)), now: date(19), calendar: calendar), .start(left: 2))
        XCTAssertEqual(WidgetMood(snapshot(open: ["a"], done: 2, lastActive: date(19), now: date(19)), now: date(19), calendar: calendar), .going(left: 1))
        XCTAssertEqual(WidgetMood(snapshot(open: [], done: 3, lastActive: date(19), now: date(19)), now: date(19), calendar: calendar), .allDone)
    }

    func testEveningNudgeOnlyWhenStreakAtRisk() {
        let atRisk = snapshot(open: ["a"], done: 0, streak: 4, lastActive: date(18), now: date(19))
        XCTAssertEqual(WidgetMood(atRisk, now: date(19, 19), calendar: calendar), .saveStreak(days: 4))
        XCTAssertEqual(WidgetMood(atRisk, now: date(19, 9), calendar: calendar), .start(left: 1))
        let noStreak = snapshot(open: ["a"], done: 0, now: date(19))
        XCTAssertEqual(WidgetMood(noStreak, now: date(19, 20), calendar: calendar), .start(left: 1))
    }

    func testSaveLoadAndPublishSkipsUnchanged() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "WidgetSnapshotTests"))
        defaults.removePersistentDomain(forName: "WidgetSnapshotTests")
        let s = snapshot(open: ["a"], done: 1, now: date(19))
        WidgetSync.publish(s, defaults: defaults)
        XCTAssertEqual(WidgetSnapshot.load(from: defaults), s)
        WidgetSync.publish(s, defaults: defaults)
        XCTAssertEqual(WidgetSnapshot.load(from: defaults), s)
    }

    func testCopyInBothLanguages() {
        XCTAssertEqual(WidgetCopy(isChinese: false).line(for: .going(left: 2)), "2 to go, keep rolling!")
        XCTAssertEqual(WidgetCopy(isChinese: true).line(for: .going(left: 2)), "还剩 2 件，冲！")
        XCTAssertEqual(WidgetCopy(isChinese: false).inline(done: 1, total: 3, streak: 0), "1/3 done")
        XCTAssertEqual(WidgetCopy(isChinese: false).inline(done: 1, total: 3, streak: 2), "🔥2 · 1/3 done")
    }
}
