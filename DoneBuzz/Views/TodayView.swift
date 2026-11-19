import SwiftData
import SwiftUI

struct TodayView: View {
    /// Opens the Settings sheet (owned by RootView).
    let onSettings: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.strings) private var s
    @Query private var allTodos: [Todo]

    @State private var editing: Todo?
    /// Refreshed whenever the app comes forward, so yesterday's finished items drop off.
    @State private var now = Date()
    /// Bumped each time an item is completed; every bump makes the cat hop for a coin.
    @State private var hops = 0

    init(onSettings: @escaping () -> Void) {
        self.onSettings = onSettings
        // Only ask the database for what this screen can show (open items, plus anything
        // finished since midnight) so years of history are never loaded here.
        let dayStart = Calendar.current.startOfDay(for: .now)
        let longAgo = Date.distantPast
        _allTodos = Query(
            filter: #Predicate<Todo> { todo in
                todo.completedAt == nil || (todo.completedAt ?? longAgo) >= dayStart
            },
            sort: \Todo.createdAt,
            order: .reverse
        )
    }

    /// Everything still open, plus whatever was finished today. Finished items keep their place
    /// (gold) for the rest of the day so the day's progress stays visible, and can be un-ticked.
    private var todos: [Todo] {
        allTodos.filter { todo in
            guard let completedAt = todo.completedAt else { return true }
            return Calendar.current.isDate(completedAt, inSameDayAs: now)
        }
    }

    private var doneCount: Int {
        todos.filter { $0.completedAt != nil }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 20)
                // Drawn above the list so the coin can fly over it.
                .zIndex(1)

            if todos.isEmpty {
                emptyState
                    .frame(maxHeight: .infinity)
            } else {
                list
            }
        }
        .sheet(item: $editing) { todo in
            TodoEditorSheet(todo: todo) { title, minutes in
                todo.title = title
                todo.durationMinutes = minutes
            }
            .environment(\.strings, s)
        }
        .onAppear {
            now = Date()
            FeedbackService.shared.prepare()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { now = Date() }
        }
        .task {
            // Keeps "today" right if the app stays open past midnight.
            for await _ in NotificationCenter.default.notifications(named: .NSCalendarDayChanged) {
                now = Date()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(s.todoTab)
                    .font(Theme.screenTitle)
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 8)
                CoinCounter(count: doneCount)
                settingsButton
            }

            if !todos.isEmpty {
                Text(s.progress(done: doneCount, left: todos.count - doneCount))
                    .font(Theme.progress)
                    .tracking(Theme.titleTracking)
                    .foregroundStyle(Theme.ink)
            }

            StageView(done: doneCount, total: todos.count, hops: hops)
                .padding(.top, 4)
        }
        .padding(.top, 8)
    }

    private var settingsButton: some View {
        Button(action: onSettings) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(width: 44, height: 44)
                .background(Color.white, in: Circle())
                .gameOutline(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(s.settings)
    }

    private var list: some View {
        ScrollViewReader { proxy in
            listContent
                // A newly added item lands at the top; bring it into view even if the list was scrolled down.
                .onChange(of: todos.first?.id) { _, newest in
                    guard let newest else { return }
                    withAnimation { proxy.scrollTo(newest, anchor: .top) }
                }
        }
    }

    private var listContent: some View {
        List {
            ForEach(todos) { todo in
                TodoRow(todo: todo, onEdit: { editing = todo }) {
                    if todo.completedAt == nil {
                        todo.completedAt = .now
                        hops += 1
                    } else {
                        todo.completedAt = nil
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 12, trailing: 20))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        modelContext.delete(todo)
                    } label: {
                        Label(s.delete, systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 12, for: .scrollContent)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            s.emptyTitle,
            systemImage: "sparkles",
            description: Text(s.emptyHint)
        )
        .foregroundStyle(Theme.ink)
    }
}
