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

    @StateObject private var speech = SpeechInput()
    /// What was already typed when dictation started; spoken words are appended to it.
    @State private var titleBeforeDictation = ""

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
            Text(isEditing ? "编辑待办" : "新建待办")
                .font(Theme.sheetTitle)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    TextField("要做什么？", text: $title, axis: .vertical)
                        .font(Theme.itemTitle)
                        .tracking(Theme.titleTracking)
                        .lineLimit(1...3)
                        .padding(14)
                        .background(Theme.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .focused($titleFocused)

                    micButton
                }
                if speech.isRecording {
                    Text("正在聆听… 说完后再点一下麦克风")
                        .font(Theme.hint)
                        .foregroundStyle(Theme.accent)
                } else if let message = speech.errorMessage {
                    Text(message)
                        .font(Theme.hint)
                        .foregroundStyle(.red)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("需要多久？（可选）")
                    .font(Theme.label)
                    .foregroundStyle(.secondary)
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                    spacing: 10
                ) {
                    ForEach(DurationOption.all, id: \.self) { option in
                        chip(for: option)
                    }
                }
            }

            Button(action: save) {
                Text(isEditing ? "保存" : "添加")
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
        .presentationDetents([.height(500)])
        .presentationDragIndicator(.visible)
        .onAppear { titleFocused = true }
        .onDisappear { speech.stop() }
        .onChange(of: speech.isRecording) { _, recording in
            if recording { titleBeforeDictation = title }
        }
        .onChange(of: speech.transcript) { _, spoken in
            guard !spoken.isEmpty else { return }
            title = titleBeforeDictation + spoken
        }
    }

    private var micButton: some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            speech.toggle()
        } label: {
            Image(systemName: speech.isRecording ? "stop.fill" : "mic.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(speech.isRecording ? .white : Theme.accent)
                .frame(width: 54, height: 54)
                .background(speech.isRecording ? Color.red : Theme.accent.opacity(0.14), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(speech.isRecording ? "停止语音输入" : "语音输入")
    }

    private func chip(for option: Int) -> some View {
        let selected = minutes == option
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            // Tapping the selected chip again clears it.
            minutes = selected ? nil : option
        } label: {
            Text(DurationOption.chipLabel(for: option))
                .font(Theme.label)
                .foregroundStyle(selected ? .white : Theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? Theme.accent : Theme.accent.opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func save() {
        guard !trimmedTitle.isEmpty else { return }
        speech.stop()
        onSave(trimmedTitle, minutes)
        dismiss()
    }
}
