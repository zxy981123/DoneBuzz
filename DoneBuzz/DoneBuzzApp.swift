import SwiftData
import SwiftUI
import UIKit

@main
struct DoneBuzzApp: App {
    init() {
        Self.useRoundedNavigationTitles()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: Todo.self)
    }

    /// Makes the big screen titles ("To do", "Done") match the chunky rounded type used in the lists.
    private static func useRoundedNavigationTitles() {
        let base = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
        guard let rounded = base.withSymbolicTraits(.traitBold)?.withDesign(.rounded) else { return }
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont(descriptor: rounded, size: 0)
        ]
    }
}
