import XCTest
@testable import DoneBuzz

final class HapticPatternTests: XCTestCase {
    private let patterns: [(String, HapticPattern)] = [
        ("taskCompleted", .taskCompleted),
        ("dayCleared", .dayCleared),
    ]

    func testValuesAreInRangeAndTimesNeverNegative() {
        for (name, pattern) in patterns {
            for tap in pattern.taps {
                XCTAssert((0...1).contains(tap.intensity), name)
                XCTAssert((0...1).contains(tap.sharpness), name)
                XCTAssertGreaterThanOrEqual(tap.time, 0, name)
            }
            for buzz in pattern.buzzes {
                XCTAssert((0...1).contains(buzz.intensity), name)
                XCTAssert((0...1).contains(buzz.endIntensity), name)
                XCTAssertGreaterThan(buzz.duration, 0, name)
            }
        }
    }

    func testTapsAreInTimeOrder() {
        for (name, pattern) in patterns {
            let times = pattern.taps.map(\.time)
            XCTAssertEqual(times, times.sorted(), name)
        }
    }

    func testCompletionBuzzIsShortAndPeaksWithTheCoin() {
        let pattern = HapticPattern.taskCompleted
        XCTAssertLessThan(pattern.duration, 0.6, "a single completion stays snappy")
        let strongest = pattern.taps.filter { $0.time > 0 }.max { $0.intensity < $1.intensity }
        XCTAssertEqual(strongest?.time ?? -1, 0.22, accuracy: 0.001, "the hardest tap lands with the coin")
    }

    func testDayClearedIsBiggerThanASingleCompletion() {
        XCTAssertGreaterThan(HapticPattern.dayCleared.duration, HapticPattern.taskCompleted.duration)
        XCTAssertGreaterThan(HapticPattern.dayCleared.taps.count, HapticPattern.taskCompleted.taps.count)
        let roll = HapticPattern.dayCleared.taps.prefix(8).map(\.intensity)
        XCTAssertEqual(roll, roll.sorted(), "the drum-roll builds up")
    }

    func testBuildsACoreHapticsPattern() {
        for (name, pattern) in patterns {
            XCTAssertNoThrow(try pattern.makePattern(), name)
        }
    }
}
