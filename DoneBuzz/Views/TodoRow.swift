import SwiftUI

struct TodoRow: View {
    let todo: Todo
    /// Called when the card (not the circle) is tapped.
    let onEdit: () -> Void
    /// Called after the celebration animation has played.
    let onComplete: () -> Void

    @State private var isDone = false
    @State private var shake: CGFloat = 0

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Button(action: complete) {
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
                .scaleEffect(isDone ? 1.15 : 1)
                .contentShape(Rectangle().inset(by: -8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark as done")

            VStack(alignment: .leading, spacing: 10) {
                Text(todo.title)
                    .font(Theme.itemTitle)
                    .lineSpacing(3)
                    .strikethrough(isDone, color: .secondary)
                    .foregroundStyle(isDone ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)
                if let minutes = todo.durationMinutes {
                    DurationBadge(minutes: minutes)
                }
            }
            .padding(.top, 6)

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(Theme.card, in: cardShape)
        .overlay(cardShape.strokeBorder(Color.primary.opacity(0.08), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.07), radius: 5, y: 3)
        .contentShape(cardShape)
        .onTapGesture {
            if !isDone { onEdit() }
        }
        .modifier(ShakeEffect(animatableData: shake))
    }

    private func complete() {
        guard !isDone else { return }
        FeedbackService.shared.taskCompleted()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            isDone = true
        }
        withAnimation(.linear(duration: 0.45)) {
            shake = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            onComplete()
        }
    }
}
