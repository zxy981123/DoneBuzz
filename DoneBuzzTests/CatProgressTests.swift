import XCTest
@testable import DoneBuzz

final class CatProgressTests: XCTestCase {
    private var calendar = Calendar(identifier: .gregorian)
    private lazy var now: Date = date(2026, 11, 19, hour: 12)
    private lazy var today: Date = calendar.startOfDay(for: now)

    override func setUp() {
        super.setUp()
        calendar.timeZone = TimeZone(identifier: "UTC")!
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
    }

    private func cat(done: Int, total: Int) -> CatProgress {
        .fresh(done: done, total: total, day: today)
    }

    private func apply(_ progress: inout CatProgress, done: Int, total: Int) {
        progress.update(done: done, total: total, now: now, calendar: calendar)
    }

    func testStartsAtTheBeginning() {
        XCTAssertEqual(cat(done: 0, total: 0).position, 0)
        XCTAssertEqual(cat(done: 0, total: 4).position, 0)
    }

    func testWalksAnEqualShareForEachItemFinished() {
        var p = cat(done: 0, total: 4)
        apply(&p, done: 1, total: 4); XCTAssertEqual(p.position, 0.25, accuracy: 1e-9)
        apply(&p, done: 2, total: 4); XCTAssertEqual(p.position, 0.5, accuracy: 1e-9)
        apply(&p, done: 3, total: 4); XCTAssertEqual(p.position, 0.75, accuracy: 1e-9)
        apply(&p, done: 4, total: 4); XCTAssertEqual(p.position, 1, accuracy: 1e-9)
    }

    /// The reported bug: finish some, add one, and the cat used to walk backwards.
    func testAddingAnItemNeverMovesTheCatBack() {
        var p = cat(done: 0, total: 3)
        apply(&p, done: 1, total: 3)
        apply(&p, done: 2, total: 3)
        let before = p.position
        apply(&p, done: 2, total: 4)
        XCTAssertEqual(p.position, before, accuracy: 1e-9)
        apply(&p, done: 2, total: 6)
        XCTAssertEqual(p.position, before, accuracy: 1e-9)
    }

    func testStillReachesTheFlagExactlyWhenTheLastItemIsFinishedAfterAdding() {
        var p = cat(done: 0, total: 3)
        apply(&p, done: 1, total: 3)
        apply(&p, done: 2, total: 3)
        apply(&p, done: 2, total: 5) // two more added
        var last = p.position
        for done in 3...5 {
            apply(&p, done: done, total: 5)
            XCTAssertGreaterThan(p.position, last, "the cat moves forward at \(done)/5")
            last = p.position
        }
        XCTAssertEqual(p.position, 1, accuracy: 1e-9)
    }

    func testUnTickingTakesBackExactlyTheLastStep() {
        var p = cat(done: 0, total: 4)
        apply(&p, done: 1, total: 4)
        apply(&p, done: 2, total: 4)
        apply(&p, done: 3, total: 4)
        apply(&p, done: 2, total: 4); XCTAssertEqual(p.position, 0.5, accuracy: 1e-9)
        apply(&p, done: 1, total: 4); XCTAssertEqual(p.position, 0.25, accuracy: 1e-9)
        apply(&p, done: 0, total: 4); XCTAssertEqual(p.position, 0, accuracy: 1e-9)
    }

    func testTickThenUntickAfterAddingReturnsToTheSamePlace() {
        var p = cat(done: 0, total: 3)
        apply(&p, done: 1, total: 3)
        apply(&p, done: 1, total: 5)
        let before = p.position
        apply(&p, done: 2, total: 5)
        XCTAssertGreaterThan(p.position, before)
        apply(&p, done: 1, total: 5)
        XCTAssertEqual(p.position, before, accuracy: 1e-9)
    }

    func testDeletingItemsDoesNotMoveTheCatBackwards() {
        var p = cat(done: 0, total: 4)
        apply(&p, done: 1, total: 4)
        apply(&p, done: 2, total: 4)
        let before = p.position
        apply(&p, done: 2, total: 3) // deleted an open item
        XCTAssertEqual(p.position, before, accuracy: 1e-9)
    }

    func testDeletingTheLastOpenItemSendsTheCatToTheFlag() {
        var p = cat(done: 0, total: 3)
        apply(&p, done: 1, total: 3)
        apply(&p, done: 2, total: 3)
        apply(&p, done: 2, total: 2)
        XCTAssertEqual(p.position, 1, accuracy: 1e-9)
    }

    func testDeletingEveryFinishedItemSendsTheCatHome() {
        var p = cat(done: 0, total: 3)
        apply(&p, done: 1, total: 3)
        apply(&p, done: 0, total: 2)
        XCTAssertEqual(p.position, 0, accuracy: 1e-9)
    }

    func testAddingAfterEverythingIsDoneLeavesTheCatAtTheFlag() {
        var p = cat(done: 0, total: 2)
        apply(&p, done: 1, total: 2)
        apply(&p, done: 2, total: 2)
        apply(&p, done: 2, total: 3)
        XCTAssertEqual(p.position, 1, accuracy: 1e-9)
        apply(&p, done: 3, total: 3)
        XCTAssertEqual(p.position, 1, accuracy: 1e-9)
    }

    func testEmptyListSendsTheCatHome() {
        var p = cat(done: 0, total: 2)
        apply(&p, done: 1, total: 2)
        apply(&p, done: 0, total: 0)
        XCTAssertEqual(p.position, 0)
    }

    func testSeveralChangesAtOnceFallBackToTheShareDone() {
        var p = cat(done: 0, total: 2)
        apply(&p, done: 3, total: 4)
        XCTAssertEqual(p.position, 0.75, accuracy: 1e-9)
    }

    func testUnchangedCountsLeaveThePositionAlone() {
        var p = cat(done: 0, total: 3)
        apply(&p, done: 1, total: 3)
        apply(&p, done: 1, total: 5)
        let before = p
        apply(&p, done: 1, total: 5)
        XCTAssertEqual(p, before)
    }

    func testANewDayStartsFromTheShareDone() {
        var p = cat(done: 0, total: 3)
        apply(&p, done: 2, total: 3)
        let tomorrow = date(2026, 11, 20, hour: 9)
        p.update(done: 0, total: 2, now: tomorrow, calendar: calendar)
        XCTAssertEqual(p.position, 0)
        XCTAssertEqual(p.day, calendar.startOfDay(for: tomorrow))
    }

    func testSurvivesBeingSavedAndLoaded() throws {
        let defaults = UserDefaults(suiteName: "CatProgressTests-\(UUID().uuidString)")!
        var p = cat(done: 0, total: 4)
        apply(&p, done: 1, total: 4)
        apply(&p, done: 1, total: 6)
        p.save(defaults: defaults)
        XCTAssertEqual(CatProgress.load(defaults: defaults, now: now, calendar: calendar), p)
    }

    func testLoadWithNothingSavedStartsFresh() {
        let defaults = UserDefaults(suiteName: "CatProgressTests-\(UUID().uuidString)")!
        let loaded = CatProgress.load(defaults: defaults, now: now, calendar: calendar)
        XCTAssertEqual(loaded.position, 0)
        XCTAssertEqual(loaded.day, today)
    }
}
