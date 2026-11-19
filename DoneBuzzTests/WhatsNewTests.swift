import XCTest
@testable import DoneBuzz

final class WhatsNewTests: XCTestCase {
    func testFreshInstallDoesNotShowItButRemembersTheRelease() {
        XCTAssertEqual(WhatsNew.launchAction(seenRelease: 0, hasExistingData: false, current: 2), .recordSilently)
    }

    func testSomeoneWhoUsedTheAppBeforeThisScreenExistedSeesIt() {
        XCTAssertEqual(WhatsNew.launchAction(seenRelease: 0, hasExistingData: true, current: 2), .show)
    }

    func testAnUpdateWithNewFeaturesShowsIt() {
        XCTAssertEqual(WhatsNew.launchAction(seenRelease: 1, hasExistingData: true, current: 2), .show)
        XCTAssertEqual(WhatsNew.launchAction(seenRelease: 1, hasExistingData: false, current: 2), .show)
    }

    func testOnceSeenItStaysAway() {
        XCTAssertEqual(WhatsNew.launchAction(seenRelease: 2, hasExistingData: true, current: 2), .nothing)
        XCTAssertEqual(WhatsNew.launchAction(seenRelease: 3, hasExistingData: true, current: 2), .nothing)
    }

    func testEveryItemHasTextInBothLanguages() {
        for strings in [Strings(language: .chinese), Strings(language: .english)] {
            let items = strings.whatsNewItems
            XCTAssertFalse(items.isEmpty)
            XCTAssertEqual(Set(items.map(\.id)).count, items.count, "ids are unique")
            for item in items {
                XCTAssertFalse(item.title.isEmpty)
                XCTAssertFalse(item.body.isEmpty)
            }
        }
        XCTAssertEqual(Strings(language: .chinese).whatsNewItems.count, Strings(language: .english).whatsNewItems.count)
    }
}

final class FocusTimerTests: XCTestCase {
    func testFocusKeyIsStableForATask() {
        let todo = Todo(title: "Write", durationMinutes: 25, createdAt: Date(timeIntervalSinceReferenceDate: 1000))
        XCTAssertEqual(todo.focusKey, todo.focusKey)
        let other = Todo(title: "Write", durationMinutes: 25, createdAt: Date(timeIntervalSinceReferenceDate: 1001))
        XCTAssertNotEqual(todo.focusKey, other.focusKey)
    }

    func testLiveActivityStateRoundTrips() throws {
        let state = FocusActivityAttributes.ContentState(
            startDate: Date(timeIntervalSinceReferenceDate: 0),
            endDate: Date(timeIntervalSinceReferenceDate: 1500)
        )
        let data = try JSONEncoder().encode(state)
        XCTAssertEqual(try JSONDecoder().decode(FocusActivityAttributes.ContentState.self, from: data), state)
    }

    @MainActor
    func testNothingIsRunningUntilStarted() {
        XCTAssertFalse(FocusTimer.shared.isRunning(for: "anything"))
    }

    func testFocusStringsExistInBothLanguages() {
        for s in [Strings(language: .chinese), Strings(language: .english)] {
            XCTAssertFalse(s.focusStart.isEmpty)
            XCTAssertFalse(s.timesUp.isEmpty)
            XCTAssertTrue(s.focusEnded("X").contains("X"))
        }
    }
}
