import SwiftData
import SwiftUI

@main
struct DoneBuzzApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: Todo.self)
    }
}
