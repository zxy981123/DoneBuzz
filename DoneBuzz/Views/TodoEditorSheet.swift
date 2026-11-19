import SwiftUI

/// Used both to add a new item and to edit an existing one.
struct TodoEditorSheet: View {
    private let isEditing: Bool
    /// (title, optional duration in minutes)
    private let onSave: (String, Int?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.strings) private var s
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
            Text(isEditing ? s.editItem : s.newItem)
                .font(Theme.sheetTitle)
                .foregroundStyle(Theme.ink)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    TextField(s.titlePlaceholder, text: $title, axis: .vertical)
                        .font(Theme.itemTitle)
                        .tracking(Theme.titleTracking)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1...3)
                        .padding(14)
                        .background(Theme.skyLight.opacity(0.6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.ink, lineWidth: 2))
                        .focused($titleFocused)

                    micButton
                }
                if speech.isRecording {
                    Text(s.listening)
                        .font(Theme.hint)
                        .foregroundStyle(Theme.ink)
                } else if let problem = speech.problem {
                    Text(s.message(for: problem))
                        .font(Theme.hint)
                        .foregroundStyle(Theme.recording)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(s.howLong)
                    .font(Theme.label)
                    .foregroundStyle(Theme.muted)
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                    spacing: 12
                ) {
                    ForEach(DurationOption.all, id: \.self) { option in
                        chip(for: option)
                    }
                }
            }

            Button(action: save) {
                Text(isEditing ? s.save : s.add)
                    .font(Theme.button)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Theme.gold, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .gameOutline(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(trimmedTitle.isEmpty)
            .opacity(trimmedTitle.isEmpty ? 0.45 : 1)
        }
        .padding(22)
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(510)])
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
            speech.toggle(locale: s.speechLocale)
        } label: {
            Image(systemName: speech.isRecording ? "stop.fill" : "mic.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(speech.isRecording ? .white : Theme.ink)
                .frame(width: 54, height: 54)
                .background(speech.isRecording ? Theme.recording : Color.white, in: Circle())
                .overlay(Circle().strokeBorder(Theme.ink, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(speech.isRecording ? s.stopVoiceInput : s.voiceInput)
    }

    private func chip(for option: Int) -> some View {
        let selected = minutes == option
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            // Tapping the selected chip again clears it.
            minutes = selected ? nil : option
        } label: {
            Text(s.chipDuration(option))
                .font(Theme.label)
                .foregroundStyle(selected ? Theme.ink : Theme.tagText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? Theme.gold : Theme.tagBackground, in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.ink, lineWidth: selected ? 3 : 2))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func save() {
        guard !trimmedTitle.isEmpty else { return }
        speech.stop()
        onSave(trimmedTitle, minutes)
        dismiss()
    }
}
