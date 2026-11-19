import SwiftUI

/// The list of new features: shown once after an update, and any time from Settings.
struct WhatsNewSheet: View {
    @Environment(\.strings) private var s
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(s.whatsNewTitle)
                            .font(Theme.sheetTitle)
                            .foregroundStyle(Theme.ink)
                        Text(s.whatsNewSubtitle)
                            .font(Theme.hint)
                            .foregroundStyle(Theme.muted)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isHeader)

                    ForEach(s.whatsNewItems) { item in
                        row(item)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 12)
            }
            .scrollBounceBehavior(.basedOnSize)

            Button {
                dismiss()
            } label: {
                Text(s.gotIt)
                    .font(Theme.button)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Theme.gold, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .gameOutline(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .background(Theme.card)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func row(_ item: WhatsNewItem) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: item.icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(width: 46, height: 46)
                .background(Theme.goldLight, in: Circle())
                .overlay(Circle().strokeBorder(Theme.ink, lineWidth: 2))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(Theme.label)
                    .foregroundStyle(Theme.ink)
                Text(item.body)
                    .font(Theme.hint)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
