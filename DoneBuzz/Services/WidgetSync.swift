import Foundation
import WidgetKit

/// Hands today's list to the home screen widget. Only reloads the widget when what it shows
/// actually changed, so WidgetKit's refresh budget is not wasted.
enum WidgetSync {
    static func publish(_ snapshot: WidgetSnapshot, defaults: UserDefaults? = UserDefaults(suiteName: WidgetSnapshot.appGroup)) {
        guard WidgetSnapshot.load(from: defaults) != snapshot else { return }
        snapshot.save(to: defaults)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetSnapshot.widgetKind)
    }
}
