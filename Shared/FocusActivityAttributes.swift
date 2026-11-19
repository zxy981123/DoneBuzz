import ActivityKit
import Foundation

/// The focus countdown shown in the Dynamic Island and on the Lock Screen.
/// Shared by the app (which starts and ends it) and the widget extension (which draws it).
struct FocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var startDate: Date
        var endDate: Date
    }

    /// Which task this timer belongs to (see `Todo.focusKey`).
    var taskKey: String
    var title: String
    /// Already translated, because the extension does not know the app's language setting.
    var focusingLabel: String
    var timesUpLabel: String
}
