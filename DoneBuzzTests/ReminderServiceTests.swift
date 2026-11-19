import UserNotifications
import XCTest
@testable import DoneBuzz

private final class FakeCenter: NotificationCenterProviding {
    var status: ReminderAccess
    var grantsPermission: Bool
    private(set) var asked = 0
    private(set) var scheduled: [UNNotificationRequest] = []
    private(set) var cancelled: [[String]] = []

    init(status: ReminderAccess, grantsPermission: Bool = true) {
        self.status = status
        self.grantsPermission = grantsPermission
    }

    func accessStatus() async -> ReminderAccess { status }

    func requestAccess() async -> Bool {
        asked += 1
        status = grantsPermission ? .allowed : .denied
        return grantsPermission
    }

    func schedule(_ requests: [UNNotificationRequest]) async { scheduled += requests }
    func cancel(identifiers: [String]) { cancelled.append(identifiers) }
}

final class ReminderServiceTests: XCTestCase {
    private let chinese = Strings(language: .chinese)
    private let english = Strings(language: .english)

    private func trigger(_ request: UNNotificationRequest) -> UNCalendarNotificationTrigger {
        request.trigger as! UNCalendarNotificationTrigger
    }

    func testBuildsOneRepeatingRequestForEachWeekday() {
        let requests = ReminderService().requests(minutes: 9 * 60 + 30, strings: english)
        XCTAssertEqual(requests.count, 7)
        XCTAssertEqual(Set(requests.map(\.identifier)).count, 7)
        XCTAssertEqual(requests.map { trigger($0).dateComponents.weekday }, Array(1...7))
        for request in requests {
            XCTAssertTrue(trigger(request).repeats)
            XCTAssertEqual(trigger(request).dateComponents.hour, 9)
            XCTAssertEqual(trigger(request).dateComponents.minute, 30)
            XCTAssertEqual(request.content.title, "DoneBuzz")
            XCTAssertFalse(request.content.body.isEmpty)
        }
    }

    func testTimeIsClampedToTheDay() {
        let late = ReminderService().requests(minutes: 99_999, strings: english)
        XCTAssertEqual(trigger(late[0]).dateComponents.hour, 23)
        XCTAssertEqual(trigger(late[0]).dateComponents.minute, 59)
        let early = ReminderService().requests(minutes: -5, strings: english)
        XCTAssertEqual(trigger(early[0]).dateComponents.hour, 0)
        XCTAssertEqual(trigger(early[0]).dateComponents.minute, 0)
    }

    func testMessagesFollowTheAppLanguageAndVaryThroughTheWeek() {
        let zh = ReminderService().requests(minutes: 540, strings: chinese).map(\.content.body)
        let en = ReminderService().requests(minutes: 540, strings: english).map(\.content.body)
        XCTAssertEqual(Set(zh).count, 7)
        XCTAssertEqual(Set(en).count, 7)
        XCTAssertTrue(zh.allSatisfy { $0.unicodeScalars.contains { $0.value > 0x2E80 } })
        XCTAssertTrue(en.allSatisfy { $0.unicodeScalars.allSatisfy { $0.value < 0x2E80 } })
    }

    func testEnableAsksOncePermissionIsUndecidedThenSchedules() async {
        let center = FakeCenter(status: .notAsked, grantsPermission: true)
        let result = await ReminderService(center: center).enable(minutes: 540, strings: english)
        XCTAssertEqual(result, .enabled)
        XCTAssertEqual(center.asked, 1)
        XCTAssertEqual(center.scheduled.count, 7)
    }

    func testEnableDoesNotAskAgainWhenAlreadyAllowed() async {
        let center = FakeCenter(status: .allowed)
        let result = await ReminderService(center: center).enable(minutes: 540, strings: english)
        XCTAssertEqual(result, .enabled)
        XCTAssertEqual(center.asked, 0)
        XCTAssertEqual(center.scheduled.count, 7)
    }

    func testEnableReportsDeniedWhenTheUserSaysNoAndSchedulesNothing() async {
        let center = FakeCenter(status: .notAsked, grantsPermission: false)
        let result = await ReminderService(center: center).enable(minutes: 540, strings: english)
        XCTAssertEqual(result, .denied)
        XCTAssertTrue(center.scheduled.isEmpty)
    }

    func testEnableNeverReasksAfterAPreviousDenial() async {
        let center = FakeCenter(status: .denied)
        let result = await ReminderService(center: center).enable(minutes: 540, strings: english)
        XCTAssertEqual(result, .denied)
        XCTAssertEqual(center.asked, 0)
        XCTAssertTrue(center.scheduled.isEmpty)
    }

    func testRescheduleReplacesTheOldOnesInsteadOfAddingToThem() async {
        let center = FakeCenter(status: .allowed)
        let service = ReminderService(center: center)
        _ = await service.enable(minutes: 540, strings: english)
        let stillOn = await service.sync(enabled: true, minutes: 18 * 60, strings: chinese)
        XCTAssertTrue(stillOn)
        XCTAssertEqual(center.cancelled.last, ReminderService.identifiers)
        let latest = Array(center.scheduled.suffix(7))
        XCTAssertEqual(trigger(latest[0]).dateComponents.hour, 18)
    }

    func testDisableCancelsEveryReminder() {
        let center = FakeCenter(status: .allowed)
        ReminderService(center: center).disable()
        XCTAssertEqual(center.cancelled.last, ReminderService.identifiers)
    }

    func testSyncTurnsRemindersOffWhenPermissionWasTakenAway() async {
        let center = FakeCenter(status: .denied)
        let stillOn = await ReminderService(center: center).sync(enabled: true, minutes: 540, strings: english)
        XCTAssertFalse(stillOn)
        XCTAssertTrue(center.scheduled.isEmpty)
        XCTAssertEqual(center.cancelled.last, ReminderService.identifiers)
    }

    func testSyncWhileSwitchedOffCancelsAndSchedulesNothing() async {
        let center = FakeCenter(status: .allowed)
        let stillOn = await ReminderService(center: center).sync(enabled: false, minutes: 540, strings: english)
        XCTAssertFalse(stillOn)
        XCTAssertTrue(center.scheduled.isEmpty)
    }
}
