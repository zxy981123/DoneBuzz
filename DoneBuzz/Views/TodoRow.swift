import SwiftUI

/// One item drawn as a little grass-topped platform, with the check button on the right
/// where the thumb rests.
struct TodoRow: View {
    let todo: Todo
    /// Called when the card (not the check button) is tapped.
    let onEdit: () -> Void
    /// Called when the check button is tapped: completes an active item, or un-completes a finished one.
    let onToggle: () -> Void

    @Environment(\.strings) private var s
    @State private var squishes = 0
    @State private var coinPops = 0

    private var isDone: Bool { todo.completedAt != nil }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                Text(todo.title)
                    .font(Theme.itemTitle)
                    .tracking(Theme.titleTracking)
                    .lineSpacing(Theme.titleLineSpacing)
                    // No strike-through: a crossed-out line is hard to re-read. The gold card and button say "done".
                    .foregroundStyle(isDone ? Theme.muted : Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let minutes = todo.durationMinutes {
                    DurationBadge(minutes: minutes)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            checkButton
        }
        .padding(.top, 22)
        .padding(.bottom, 18)
        .padding(.leading, 20)
        .padding(.trailing, 16)
        .background {
            // Grass along the top edge turns each card into a platform.
            ZStack(alignment: .top) {
                isDone ? Theme.doneCard : Theme.card
                Theme.grass
                    .opacity(isDone ? 0.5 : 1)
                    .frame(height: 9)
            }
            .clipShape(cardShape)
        }
        .overlay(cardShape.strokeBorder(Theme.ink, lineWidth: Theme.outline))
        // The dirt underneath the platform.
        .background(cardShape.fill(Theme.dirtDark).offset(y: 6))
        .contentShape(cardShape)
        .onTapGesture {
            if !isDone { onEdit() }
        }
    }

    private var checkButton: some View {
        Button(action: toggle) {
            ZStack {
                Circle().fill(isDone ? Theme.gold : Color.white)
                Circle().strokeBorder(Theme.ink, lineWidth: Theme.outline)
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(Theme.ink)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 54, height: 54)
            .background(Circle().fill(Theme.ink).offset(y: 4))
            .keyframeAnimator(initialValue: CGFloat(1), trigger: squishes) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(0.8, duration: 0.1)
                    CubicKeyframe(1.14, duration: 0.12)
                    SpringKeyframe(1, duration: 0.2)
                }
            }
            .overlay(alignment: .top) { miniCoin }
            .contentShape(Rectangle().inset(by: -8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isDone ? s.markNotDone : s.markDone)
    }

    /// A small coin that pops out of the button when the item is completed.
    private var miniCoin: some View {
        PixelSprite.coin
            .frame(width: 22, height: 22)
            .keyframeAnimator(initialValue: CoinPop(), trigger: coinPops) { content, pop in
                content
                    .rotation3DEffect(.degrees(pop.spin), axis: (x: 0, y: 1, z: 0))
                    .offset(y: pop.y)
                    .opacity(pop.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.y) {
                    LinearKeyframe(-4, duration: 0.01)
                    CubicKeyframe(-30, duration: 0.6)
                }
                KeyframeTrack(\.spin) {
                    LinearKeyframe(0, duration: 0.01)
                    LinearKeyframe(720, duration: 0.6)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(1, duration: 0.08)
                    LinearKeyframe(1, duration: 0.25)
                    LinearKeyframe(0, duration: 0.28)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func toggle() {
        squishes += 1
        if isDone {
            UISelectionFeedbackGenerator().selectionChanged()
        } else {
            FeedbackService.shared.taskCompleted()
            coinPops += 1
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            onToggle()
        }
    }
}
