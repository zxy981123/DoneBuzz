import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("待办", systemImage: "checklist") }
            HistoryView()
                .tabItem { Label("已完成", systemImage: "checkmark.seal.fill") }
        }
        .tint(Theme.accent)
    }
}
