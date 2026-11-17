import SwiftUI

/// Used both to add a new item and to edit an existing one.
struct TodoEditorSheet: View {
    private let isEditing: Bool
    /// (title, optional duration in minutes)
    private let onSave: (String, Int?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var minutes: Int?
    @FocusState private var titleFocused: Bool

    init(todo: Todo? = nil, onSave: @escaping (String, Int?) -> Void) {
        self.isEditing = todo != nil
        self.onSave = onSave
        _title = State(initialValue: todo?.title ?? "")
        _minutes = State(initialValue: todo?.durationMinutes)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(isEditing ? "Edit item" : "New item")
                .font(Theme.sheetTitle)

            TextField("What do you need to do?", text: $title, axis: .vertical)
                .font(Theme.itemTitle)
                .lineLimit(1...3)
                .padding(14)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .focused($titleFocused)

            VStack(alignment: .leading, spacing: 10) {
                Text("How long? (optional)")
                    .font(Theme.label)
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    ForEach(DurationOption.all, id: \.self) { option in
                        chip(for: option)
                    }
                }
            }

            Button(action: save) {
                Text(isEditing ? "Save" : "Add")
                    .font(Theme.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(trimmedTitle.isEmpty)
            .opacity(trimmedTitle.isEmpty ? 0.45 : 1)
        }
        .padding(22)
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.visible)
        .onAppear { titleFocused = true }
    }

    private func chip(for option: Int) -> some View {
        let selected = minutes == option
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            // Tapping the selected chip again clears it.
            minutes = selected ? nil : option
        } label: {
            Text(DurationOption.label(for: option))
                .font(Theme.label)
                .foregroundStyle(selected ? .white : Theme.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(selected ? Theme.accent : Theme.accent.opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func save() {
        guard !trimmedTitle.isEmpty else { return }
        onSave(trimmedTitle, minutes)
        dismiss()
    }
}
