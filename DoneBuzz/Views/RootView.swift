import SwiftData
import SwiftUI

struct RootView: View {
    private enum Tab: Int {
        case todo, done
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.chinese.rawValue

    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderMinutes") private var reminderMinutes = ReminderService.defaultMinutes

    @State private var tab: Tab = .todo
    @State private var showingAdd = false
    @State private var showingSettings = false
    @State private var showingWhatsNew = false
    @AppStorage(WhatsNew.storageKey) private var whatsNewSeenRelease = 0
    /// Where the selection highlight sits (in points along the bar) while a finger is dragging it; nil at rest.
    @State private var dragX: CGFloat?
    /// The tab under the finger during a drag, so the selection tick fires once per tab crossed.
    @State private var hoverIndex: Int?

    private var strings: Strings {
        Strings(language: (AppLanguage(rawValue: languageRaw) ?? .chinese).resolved)
    }

    var body: some View {
        let s = strings
        ZStack {
            SkyBackground()

            ZStack {
                switch tab {
                case .todo:
                    TodayView(onSettings: { showingSettings = true })
                        .transition(.move(edge: .leading).combined(with: .opacity))
                case .done:
                    HistoryView()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
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
        .sheet(isPresented: $showingWhatsNew, onDismiss: {
            whatsNewSeenRelease = WhatsNew.currentRelease
        }) {
            WhatsNewSheet()
                .environment(\.strings, s)
                .environment(\.locale, s.locale)
        }
        .task {
            await FocusTimer.shared.restore()
            let hasData = ((try? modelContext.fetchCount(FetchDescriptor<Todo>())) ?? 0) > 0
            switch WhatsNew.launchAction(seenRelease: whatsNewSeenRelease, hasExistingData: hasData) {
            case .show:
                // Let the first screen settle before sliding the sheet up.
                try? await Task.sleep(for: .milliseconds(600))
                showingWhatsNew = true
            case .recordSilently:
                whatsNewSeenRelease = WhatsNew.currentRelease
            case .nothing:
                break
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet(languageRaw: $languageRaw)
                .environment(\.strings, s)
                .environment(\.locale, s.locale)
        }
        .environment(\.strings, s)
        .environment(\.locale, s.locale)
        .task(id: languageRaw) {
            // At launch and whenever the language changes, keep the scheduled wording in step.
            reminderEnabled = await ReminderService().sync(
                enabled: reminderEnabled, minutes: reminderMinutes, strings: strings
            )
        }
        .onChange(of: scenePhase) { _, _ in
            // A cancelled touch never reports its end; drop any half-finished tab drag.
            dragX = nil
            hoverIndex = nil
        }
        // The scene is a bright daytime sky; keep sheets and system controls in light mode to match.
        .preferredColorScheme(.light)
    }

    /// Tabs on the left, the + on the right where the thumb rests. iOS 26 and later get Liquid Glass;
    /// older iPhones keep the solid pixel-style bar.
    @ViewBuilder
    private func bottomBar(_ s: Strings) -> some View {
        if #available(iOS 26, *) {
            glassBar(s)
        } else {
            classicBar(s)
        }
    }

    @available(iOS 26, *)
    private func glassBar(_ s: Strings) -> some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                tabSwitcher(s, glass: true)
                    .glassEffect(.regular.interactive(), in: Capsule())

                addButton(s)
                    .frame(width: 66, height: 66)
                    .glassEffect(.regular.tint(Theme.gold).interactive(), in: Circle())
            }
        }
    }

    private func classicBar(_ s: Strings) -> some View {
        HStack(spacing: 12) {
            tabSwitcher(s, glass: false)
                .background(Color.white, in: Capsule())
                .gameOutline(Capsule(), drop: 5)

            addButton(s)
                .frame(width: 66, height: 66)
                .background(Theme.gold, in: Circle())
                .gameOutline(Circle(), drop: 5)
        }
    }

    private func addButton(_ s: Strings) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) { tab = .todo }
            showingAdd = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(s.addItem)
    }

    /// The two tabs with a highlight that slides between them. Tap a tab, or press and drag across the bar:
    /// the highlight follows the finger, swells while held, and springs onto the nearest tab on release.
    private func tabSwitcher(_ s: Strings, glass: Bool) -> some View {
        let items: [(tab: Tab, title: String, icon: String)] = [
            (.todo, s.todoTab, "checklist"),
            (.done, s.doneTab, "checkmark.seal.fill"),
        ]
        return GeometryReader { proxy in
            let inset: CGFloat = 5
            let tabWidth = (proxy.size.width - inset * 2) / CGFloat(items.count)
            let maxX = tabWidth * CGFloat(items.count - 1)
            let indicatorX = dragX ?? CGFloat(tab.rawValue) * tabWidth
            let holding = dragX != nil

            ZStack(alignment: .topLeading) {
                Capsule()
                    .fill(glass ? Theme.goldLight.opacity(0.85) : Theme.goldLight)
                    .frame(width: tabWidth, height: proxy.size.height - inset * 2)
                    .scaleEffect(holding ? 1.08 : 1)
                    .offset(x: inset + indicatorX, y: inset)
                    .animation(holding ? .interactiveSpring() : .spring(response: 0.4, dampingFraction: 0.72), value: indicatorX)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: holding)

                HStack(spacing: 0) {
                    ForEach(items, id: \.tab.rawValue) { item in
                        Label(item.title, systemImage: item.icon)
                            .font(Theme.label)
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(width: tabWidth, height: proxy.size.height)
                            .accessibilityElement(children: .combine)
                            .accessibilityAddTraits(tab == item.tab ? [.isButton, .isSelected] : .isButton)
                            .accessibilityAction { select(item.tab) }
                    }
                }
                .padding(.horizontal, inset)
            }
            .contentShape(Capsule())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let x = min(max(value.location.x - inset - tabWidth / 2, 0), maxX)
                        dragX = x
                        let index = Int((x / tabWidth).rounded())
                        if hoverIndex == nil { hoverIndex = tab.rawValue }
                        if index != hoverIndex {
                            hoverIndex = index
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                    }
                    .onEnded { value in
                        let x = min(max(value.location.x - inset - tabWidth / 2, 0), maxX)
                        let index = Int((x / tabWidth).rounded())
                        hoverIndex = nil
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                            tab = Tab(rawValue: index) ?? tab
                            dragX = nil
                        }
                    }
            )
        }
        .frame(height: 66)
        .frame(maxWidth: .infinity)
    }

    private func select(_ target: Tab) {
        guard tab != target else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) { tab = target }
    }
}
