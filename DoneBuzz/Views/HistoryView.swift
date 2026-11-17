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

    /// Dates are always shown in Chinese, whatever the device language.
    private static let chinese = Locale(identifier: "zh-Hans")

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
                        "还没有已完成的事项",
                        systemImage: "checkmark.seal",
                        description: Text("完成的事项会保存在这里。")
                    )
                } else {
                    List {
                        ForEach(days, id: \.day) { group in
                            Section {
                                ForEach(group.items) { todo in
                                    row(for: todo)
                                }
                            } header: {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(title(for: group.day))
                                    Spacer()
                                    Text(summary(for: group.items))
                                }
                                .font(Theme.label)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Theme.background)
                }
            }
            .navigationTitle("已完成")
        }
    }

    private func row(for todo: Todo) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Theme.success)

            // Title gets the full width; the time details sit together on the line below.
            VStack(alignment: .leading, spacing: 8) {
                Text(todo.title)
                    .font(Theme.historyTitle)
                    .tracking(Theme.titleTracking)
                    .lineSpacing(Theme.titleLineSpacing)
                HStack(spacing: 10) {
                    if let completedAt = todo.completedAt {
                        Text(completedAt.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(Self.chinese)))
                            .font(Theme.hint)
                            .foregroundStyle(.secondary)
                    }
                    if let minutes = todo.durationMinutes {
                        DurationBadge(minutes: minutes)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                modelContext.delete(todo)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                withAnimation { todo.completedAt = nil }
            } label: {
                Label("撤销完成", systemImage: "arrow.uturn.backward")
            }
            .tint(Theme.accent)
        }
    }

    private func title(for day: Date) -> String {
        let calendar = Calendar.current
        let date = day.formatted(.dateTime.month().day().weekday(.abbreviated).locale(Self.chinese))
        let today = calendar.startOfDay(for: .now)
        switch calendar.dateComponents([.day], from: day, to: today).day {
        case 0: return "今天 · \(date)"
        case 1: return "昨天 · \(date)"
        case 2: return "前天 · \(date)"
        default: return date
        }
    }

    /// "3 项 · 共 50 分钟" — the time is the sum of the estimates on that day's items.
    private func summary(for items: [Todo]) -> String {
        let count = "\(items.count) 项"
        let minutes = items.compactMap(\.durationMinutes).reduce(0, +)
        return minutes == 0 ? count : "\(count) · 共 \(DurationOption.label(for: minutes))"
    }
}
