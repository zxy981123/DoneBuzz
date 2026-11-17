import SwiftUI

struct TodoRow: View {
    let todo: Todo
    /// Called when the card (not the circle) is tapped.
    let onEdit: () -> Void
    /// Called when the circle is tapped: completes an active item, or un-completes a finished one.
    let onToggle: () -> Void

    @State private var shake: CGFloat = 0

    private var isDone: Bool { todo.completedAt != nil }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Button(action: toggle) {
                ZStack {
                    Circle()
                        .strokeBorder(isDone ? Theme.success : Theme.accent, lineWidth: 3.5)
                    if isDone {
                        Circle().fill(Theme.success)
                        Image(systemName: "checkmark")
                            .font(.system(size: 19, weight: .black))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 42, height: 42)
                .contentShape(Rectangle().inset(by: -8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isDone ? "标记为未完成" : "标记为完成")

            VStack(alignment: .leading, spacing: 12) {
                Text(todo.title)
                    .font(Theme.itemTitle)
                    .tracking(Theme.titleTracking)
                    .lineSpacing(Theme.titleLineSpacing)
                    // No strike-through: a crossed-out line is hard to re-read. The green card says "done".
                    .foregroundStyle(isDone ? Theme.success : .primary)
                    .fixedSize(horizontal: false, vertical: true)
                if let minutes = todo.durationMinutes {
                    DurationBadge(minutes: minutes)
                }
            }
            .padding(.top, 6)

            Spacer(minLength: 0)
        }
        .padding(20)
        // The green wash sits behind the content; on top it would swallow taps meant for the circle.
        .background(Theme.success.opacity(isDone ? 0.13 : 0), in: cardShape)
        .background(Theme.card, in: cardShape)
        .overlay(
            cardShape.strokeBorder(
                isDone ? Theme.success.opacity(0.55) : Theme.accent.opacity(0.18),
                lineWidth: 2
            )
        )
        .shadow(color: Theme.accent.opacity(isDone ? 0 : 0.10), radius: 6, y: 3)
        .contentShape(cardShape)
        .onTapGesture {
            if !isDone { onEdit() }
        }
        .modifier(ShakeEffect(animatableData: shake))
    }

    private func toggle() {
        if isDone {
            UISelectionFeedbackGenerator().selectionChanged()
        } else {
            FeedbackService.shared.taskCompleted()
            // One whole unit plays the wiggle once and lands back at rest.
            withAnimation(.linear(duration: 0.45)) {
                shake += 1
            }
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            onToggle()
        }
    }
}
