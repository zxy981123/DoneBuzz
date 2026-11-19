import XCTest
@testable import DoneBuzz

final class StreakTests: XCTestCase {
    private var calendar = Calendar(identifier: .gregorian)

    override func setUp() {
        super.setUp()
        calendar.timeZone = TimeZone(identifier: "UTC")!
    }

    /// Thursday 19 Nov 2026, afternoon.
    private var now: Date { day(0, hour: 15) }

    /// `daysAgo` days before the reference day.
    private func day(_ daysAgo: Int, hour: Int = 10) -> Date {
        let base = calendar.date(from: DateComponents(year: 2026, month: 11, day: 19, hour: hour))!
        return calendar.date(byAdding: .day, value: -daysAgo, to: base)!
    }

    private func streak(_ daysAgo: [Int]) -> StreakInfo {
        Streak.compute(completionDates: daysAgo.map { day($0) }, now: now, calendar: calendar)
    }

    func testNothingFinishedIsNoStreak() {
        XCTAssertEqual(streak([]), .empty)
    }

    func testOnlyTodayIsAStreakOfOne() {
        let info = streak([0])
        XCTAssertEqual(info.current, 1)
        XCTAssertEqual(info.best, 1)
        XCTAssertTrue(info.doneToday)
    }

    func testConsecutiveDaysCountUp() {
        let info = streak([0, 1, 2, 3])
        XCTAssertEqual(info.current, 4)
        XCTAssertEqual(info.best, 4)
    }

    func testSeveralItemsOnOneDayCountOnce() {
        let info = Streak.compute(
            completionDates: [day(0, hour: 8), day(0, hour: 9), day(0, hour: 22), day(1, hour: 1)],
            now: now, calendar: calendar
        )
        XCTAssertEqual(info.current, 2)
    }

    func testTodayNotYetDoneDoesNotBreakAStreak() {
        let info = streak([1, 2, 3])
        XCTAssertEqual(info.current, 3)
        XCTAssertFalse(info.doneToday)
    }

    func testOneRestDayDoesNotBreakTheStreak() {
        // Done today, rested yesterday, done the three days before.
        let info = streak([0, 2, 3, 4])
        XCTAssertEqual(info.current, 4)
    }

    func testTwoEmptyDaysInARowBreakIt() {
        // Done today, then two empty days, then older days.
        let info = streak([0, 3, 4, 5])
        XCTAssertEqual(info.current, 1)
        XCTAssertEqual(info.best, 3)
    }

    func testYesterdayRestedAndTodayNotYetDoneKeepsItAlive() {
        // Nothing yesterday or today yet, but done the two days before: today can still save it.
        let info = streak([2, 3])
        XCTAssertEqual(info.current, 2)
    }

    func testTwoFullEmptyDaysAndNoneTodayIsOver() {
        // Last finished three days ago: yesterday and the day before were both empty.
        let info = streak([3, 4])
        XCTAssertEqual(info.current, 0)
        XCTAssertEqual(info.best, 2)
    }

    func testOldHistoryDoesNotCountAsCurrent() {
        let info = streak([30, 31, 32])
        XCTAssertEqual(info.current, 0)
        XCTAssertEqual(info.best, 3)
    }

    func testBestIsTheLongestRunEvenWhenCurrentIsShorter() {
        let info = streak([0, 1, 10, 11, 12, 13, 14])
        XCTAssertEqual(info.current, 2)
        XCTAssertEqual(info.best, 5)
    }

    func testBestIsNeverLessThanCurrent() {
        for set in [[0], [0, 1], [1, 2, 4], [0, 2, 4, 6]] {
            let info = streak(set)
            XCTAssertGreaterThanOrEqual(info.best, info.current, "\(set)")
        }
    }

    func testWorksAcrossAMonthBoundary() {
        // 19 Nov back to 29 Oct is 22 days.
        let info = streak(Array(0..<22))
        XCTAssertEqual(info.current, 22)
    }

    func testLateNightCompletionBelongsToThatCalendarDay() {
        let late = calendar.date(from: DateComponents(year: 2026, month: 11, day: 18, hour: 23, minute: 59))!
        let info = Streak.compute(completionDates: [late, day(0)], now: now, calendar: calendar)
        XCTAssertEqual(info.current, 2)
    }
}
