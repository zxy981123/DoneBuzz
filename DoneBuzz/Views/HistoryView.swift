import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Todo> { $0.completedAt != nil },
        sort: \Todo.completedAt,
        order: .reverse
    )
    private var done: [Todo]

    /// Finished items grouped by calendar day, newest day first.
    private var days: [(day: Date, items: [Todo])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: done) { todo in
            calendar.startOfDay(for: todo.completedAt ?? todo.createdAt)
        }
        return grouped
            .map { (day: $0.key, items: $0.value) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        NavigationStack {
            Group {
                if done.isEmpty {
                    ContentUnavailableView(
                        "No finished items yet",
                        systemImage: "checkmark.seal",
                        description: Text("Items you complete will be kept here.")
                    )
                } else {
                    List {
                        ForEach(days, id: \.day) { group in
                            Section {
                                ForEach(group.items) { todo in
                                    row(for: todo)
                                }
                            } header: {
                                HStack {
                                    Text(title(for: group.day))
                                    Spacer()
                                    Text("\(group.items.count) done")
                                }
                                .font(Theme.label)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Done")
        }
    }

    private func row(for todo: Todo) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Theme.success)

            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(Theme.historyTitle)
                if let completedAt = todo.completedAt {
                    Text(completedAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            if let minutes = todo.durationMinutes {
                DurationBadge(minutes: minutes)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                modelContext.delete(todo)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                withAnimation { todo.completedAt = nil }
            } label: {
                Label("Not done", systemImage: "arrow.uturn.backward")
            }
            .tint(Theme.accent)
        }
    }

    private func title(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}
