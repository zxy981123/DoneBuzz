import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Todo> { $0.completedAt == nil },
        sort: \Todo.createdAt,
        order: .reverse
    )
    private var todos: [Todo]

    @State private var showingAdd = false
    @State private var editing: Todo?

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
            .navigationTitle("To do")
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
            .onAppear { FeedbackService.shared.prepare() }
        }
    }

    private var list: some View {
        List {
            ForEach(todos) { todo in
                TodoRow(todo: todo, onEdit: { editing = todo }) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        todo.completedAt = .now
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        modelContext.delete(todo)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 88) }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nothing to do",
            systemImage: "sparkles",
            description: Text("Tap + to add your first item.")
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
        .accessibilityLabel("Add item")
    }
}
