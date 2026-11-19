import SwiftUI

struct SettingsSheet: View {
    /// Raw value of the chosen `AppLanguage`, shared with RootView's `@AppStorage`.
    @Binding var languageRaw: String

    @Environment(\.strings) private var s
    @Environment(\.dismiss) private var dismiss
    @State private var showingWhatsNew = false

    var body: some View {
        ScrollView {
            content.padding(22)
        }
        .scrollBounceBehavior(.basedOnSize)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(s.settings)
                    .font(Theme.sheetTitle)
                    .foregroundStyle(Theme.ink)
                Spacer()
                Button(s.close) { dismiss() }
                    .font(Theme.label)
                    .foregroundStyle(Theme.ink)
            }

            VStack(alignment: .leading, spacing: 12) {
                Label(s.languageTitle, systemImage: "globe")
                    .font(Theme.label)
                    .foregroundStyle(Theme.muted)

                ForEach(AppLanguage.allCases) { option in
                    optionRow(option)
                }

                Text(s.languageFootnote)
                    .font(Theme.hint)
                    .foregroundStyle(Theme.muted)
            }

            ReminderSection()

            whatsNewRow
        }
    }

    private var whatsNewRow: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return Button {
            showingWhatsNew = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .bold))
                Text(s.whatsNewSettingsRow)
                    .font(Theme.button)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.muted)
            }
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 18)
            .frame(height: 58)
            .background(Theme.card, in: shape)
            .overlay(shape.strokeBorder(Theme.ink, lineWidth: 2))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingWhatsNew) {
            WhatsNewSheet()
                .environment(\.strings, s)
        }
    }

    private func optionRow(_ option: AppLanguage) -> some View {
        let selected = languageRaw == option.rawValue
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            languageRaw = option.rawValue
        } label: {
            HStack {
                Text(s.name(of: option))
                    .font(Theme.button)
                    .foregroundStyle(Theme.ink)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 30, height: 30)
                        .background(Theme.gold, in: Circle())
                        .overlay(Circle().strokeBorder(Theme.ink, lineWidth: 2))
                }
            }
            .padding(.horizontal, 18)
            .frame(height: 58)
            .background(selected ? Theme.goldLight : Theme.card, in: shape)
            .overlay(shape.strokeBorder(Theme.ink, lineWidth: selected ? 3 : 2))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
