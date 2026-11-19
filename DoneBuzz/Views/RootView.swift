import SwiftData
import SwiftUI

struct RootView: View {
    private enum Tab {
        case todo, done
    }

    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.chinese.rawValue

    @State private var tab: Tab = .todo
    @State private var showingAdd = false
    @State private var showingSettings = false

    private var strings: Strings {
        Strings(language: (AppLanguage(rawValue: languageRaw) ?? .chinese).resolved)
    }

    var body: some View {
        let s = strings
        ZStack {
            SkyBackground()

            Group {
                switch tab {
                case .todo:
                    TodayView(onSettings: { showingSettings = true })
                case .done:
                    HistoryView()
                }
            }
            // Lists scroll under the bar instead of stopping above it.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomBar(s)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
            }
        }
        .sheet(isPresented: $showingAdd) {
            TodoEditorSheet { title, minutes in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    modelContext.insert(Todo(title: title, durationMinutes: minutes))
                }
            }
            .environment(\.strings, s)
            .environment(\.locale, s.locale)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet(languageRaw: $languageRaw)
                .environment(\.strings, s)
                .environment(\.locale, s.locale)
        }
        .environment(\.strings, s)
        .environment(\.locale, s.locale)
        // The scene is a bright daytime sky; keep sheets and system controls in light mode to match.
        .preferredColorScheme(.light)
    }

    /// Tabs on the left, the gold + on the right where the thumb rests.
    private func bottomBar(_ s: Strings) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 5) {
                tabButton(.todo, title: s.todoTab, icon: "checklist")
                tabButton(.done, title: s.doneTab, icon: "checkmark.seal.fill")
            }
            .padding(5)
            .frame(height: 66)
            .background(Color.white, in: Capsule())
            .gameOutline(Capsule(), drop: 5)

            Button {
                tab = .todo
                showingAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 66, height: 66)
                    .background(Theme.gold, in: Circle())
                    .gameOutline(Circle(), drop: 5)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(s.addItem)
        }
    }

    private func tabButton(_ target: Tab, title: String, icon: String) -> some View {
        let selected = tab == target
        return Button {
            guard tab != target else { return }
            UISelectionFeedbackGenerator().selectionChanged()
            tab = target
        } label: {
            Label(title, systemImage: icon)
                .font(Theme.label)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(selected ? Theme.goldLight : Color.clear, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
