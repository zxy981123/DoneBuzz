import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var allTodos: [Todo]

    @State private var showingAdd = false
    @State private var editing: Todo?
    /// Refreshed whenever the app comes forward, so yesterday's finished items drop off.
    @State private var now = Date()
    /// Bumped each time an item is completed; every bump drops one burst of confetti.
    @State private var confettiBursts = 0

    init() {
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
    /// (green) for the rest of the day so the day's progress stays visible.
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
        NavigationStack {
            ZStack(alignment: .bottom) {
                Theme.background.ignoresSafeArea()

                if todos.isEmpty {
                    emptyState
                } else {
                    list
                }

                addButton
            }
            .navigationTitle("待办")
            .sheet(isPresented: $showingAdd) {
                TodoEditorSheet { title, minutes in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        modelContext.insert(Todo(title: title, durationMinutes: minutes))
                    }
                }
            }
            .sheet(item: $editing) { todo in
                TodoEditorSheet(todo: todo) { title, minutes in
                    todo.title = title
                    todo.durationMinutes = minutes
                }
            }
            .onAppear {
                now = Date()
                FeedbackService.shared.prepare()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { now = Date() }
            }
        }
        .overlay {
            ConfettiView(bursts: confettiBursts)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }

    private var list: some View {
        List {
            progressHeader
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 10, trailing: 20))

            ForEach(todos) { todo in
                TodoRow(todo: todo, onEdit: { editing = todo }) {
                    if todo.completedAt == nil {
                        todo.completedAt = .now
                        confettiBursts += 1
                    } else {
                        todo.completedAt = nil
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        modelContext.delete(todo)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 88) }
    }

    private var progressHeader: some View {
        let left = todos.count - doneCount
        let text: String
        if doneCount == 0 {
            text = "今天还有 \(left) 项要做"
        } else if left == 0 {
            text = "今天的 \(doneCount) 项全部完成 🎉"
        } else {
            text = "今天已完成 \(doneCount) 项，还剩 \(left) 项"
        }
        return VStack(alignment: .leading, spacing: 10) {
            Text(text)
                .font(Theme.progress)
                .tracking(Theme.titleTracking)
                .foregroundStyle(doneCount == 0 ? Color.primary : Theme.success)
            ProgressView(value: Double(doneCount), total: Double(max(todos.count, 1)))
                .tint(Theme.success)
                .scaleEffect(x: 1, y: 2.2, anchor: .center)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "暂无待办",
            systemImage: "sparkles",
            description: Text("点击 + 添加第一条待办。")
        )
    }

    private var addButton: some View {
        Button {
            showingAdd = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background(Theme.accent, in: Circle())
                .shadow(color: Theme.accent.opacity(0.45), radius: 12, y: 6)
        }
        .padding(.bottom, 18)
        .accessibilityLabel("添加待办")
    }
}
