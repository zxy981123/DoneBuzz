import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.strings) private var s
    @Query(
        filter: #Predicate<Todo> { $0.completedAt != nil },
        sort: \Todo.completedAt,
        order: .reverse
    )
    private var done: [Todo]
    /// Bumped at midnight so the "Today / Yesterday" labels move on while the app stays open.
    @State private var dayTick = 0

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
        content
            .id(dayTick)
            .task {
                for await _ in NotificationCenter.default.notifications(named: .NSCalendarDayChanged) {
                    dayTick += 1
                }
            }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(s.doneTab)
                .font(Theme.screenTitle)
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            if !done.isEmpty {
                StreakBanner(info: Streak.compute(completionDates: done.compactMap(\.completedAt), now: Date()))
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 4)
            }

            if done.isEmpty {
                ContentUnavailableView(
                    s.noneFinishedTitle,
                    systemImage: "checkmark.seal",
                    description: Text(s.noneFinishedHint)
                )
                .foregroundStyle(Theme.ink)
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(days, id: \.day) { group in
                        Section {
                            ForEach(group.items) { todo in
                                row(for: todo)
                                    .listRowBackground(Theme.card)
                            }
                        } header: {
                            HStack(alignment: .firstTextBaseline) {
                                Text(title(for: group.day))
                                Spacer()
                                Text(s.daySummary(
                                    count: group.items.count,
                                    minutes: group.items.compactMap(\.durationMinutes).reduce(0, +)
                                ))
                            }
                            .font(Theme.label)
                            .foregroundStyle(Theme.ink)
                            .textCase(nil)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func row(for todo: Todo) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.gold)
                Circle().strokeBorder(Theme.ink, lineWidth: 2.5)
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Theme.ink)
            }
            .frame(width: 30, height: 30)

            // Title gets the full width; the time details sit together on the line below.
            VStack(alignment: .leading, spacing: 8) {
                Text(todo.title)
                    .font(Theme.historyTitle)
                    .tracking(Theme.titleTracking)
                    .lineSpacing(Theme.titleLineSpacing)
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 10) {
                    if let completedAt = todo.completedAt {
                        Text(completedAt.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(s.locale)))
                            .font(Theme.hint)
                            .foregroundStyle(Theme.muted)
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
                Label(s.delete, systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                withAnimation { todo.completedAt = nil }
            } label: {
                Label(s.undoDone, systemImage: "arrow.uturn.backward")
            }
            .tint(Theme.ink)
        }
    }

    private func title(for day: Date) -> String {
        let calendar = Calendar.current
        let date = day.formatted(.dateTime.month().day().weekday(.abbreviated).locale(s.locale))
        let today = calendar.startOfDay(for: .now)
        let daysAgo = calendar.dateComponents([.day], from: day, to: today).day ?? -1
        guard let prefix = s.dayPrefix(daysAgo: daysAgo) else { return date }
        return "\(prefix) · \(date)"
    }
}
