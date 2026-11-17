import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("To do", systemImage: "checklist") }
            HistoryView()
                .tabItem { Label("Done", systemImage: "checkmark.seal.fill") }
        }
        .tint(Theme.accent)
    }
}
