import SwiftUI

/// A coin popping up: rises, spins and fades. Used by the stage and by each row's check button.
struct CoinPop {
    var y: CGFloat = 0
    var spin: Double = 0
    var opacity: Double = 0
}

/// Black-and-white finish flag.
struct CheckeredFlag: View {
    var body: some View {
        Canvas { context, size in
            let columns = 3
            let rows = 2
            let width = size.width / CGFloat(columns)
            let height = size.height / CGFloat(rows)
            for row in 0..<rows {
                for column in 0..<columns {
                    let rect = CGRect(x: CGFloat(column) * width, y: CGFloat(row) * height, width: width, height: height)
                    let isDark = (row + column).isMultiple(of: 2)
                    context.fill(Path(rect), with: .color(isDark ? Theme.ink : .white))
                }
            }
        }
        .frame(width: 28, height: 20)
        .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: 2))
    }
}
