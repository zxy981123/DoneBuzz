import SwiftUI

/// A sprite drawn from a grid of coloured rectangles, so pixel art stays crisp at any size
/// and the project needs no image assets.
struct PixelSprite: View {
    struct Block {
        let x: Int
        let y: Int
        let width: Int
        let height: Int
        let color: Color

        init(_ x: Int, _ y: Int, _ width: Int, _ height: Int, _ color: Color) {
            self.x = x
            self.y = y
            self.width = width
            self.height = height
            self.color = color
        }
    }

    let columns: Int
    let rows: Int
    let blocks: [Block]

    var body: some View {
        Canvas { context, size in
            let cell = min(size.width / CGFloat(columns), size.height / CGFloat(rows))
            for block in blocks {
                let rect = CGRect(
                    x: CGFloat(block.x) * cell,
                    y: CGFloat(block.y) * cell,
                    width: CGFloat(block.width) * cell,
                    height: CGFloat(block.height) * cell
                )
                context.fill(Path(rect), with: .color(block.color))
            }
        }
        .aspectRatio(CGFloat(columns) / CGFloat(rows), contentMode: .fit)
    }
}

extension PixelSprite {
    /// The hero: a little orange cat in a blue scarf.
    static let cat: PixelSprite = {
        let fur = Color(hex: 0xF08A24)
        let stripe = Color(hex: 0xC9661A)
        let innerEar = Color(hex: 0xFFC9A3)
        let cream = Color(hex: 0xFFF1DE)
        let nose = Color(hex: 0xE5577A)
        let scarf = Color(hex: 0x3D7BFF)
        let eye = Theme.ink
        return PixelSprite(columns: 12, rows: 12, blocks: [
            Block(2, 1, 2, 2, fur), Block(8, 1, 2, 2, fur),
            Block(3, 2, 1, 1, innerEar), Block(8, 2, 1, 1, innerEar),
            Block(2, 3, 8, 5, fur), Block(1, 4, 10, 3, fur),
            Block(5, 3, 2, 1, stripe),
            Block(3, 5, 1, 2, eye), Block(8, 5, 1, 2, eye),
            Block(5, 6, 2, 1, nose),
            Block(4, 7, 4, 1, cream),
            Block(10, 8, 1, 1, fur),
            Block(2, 8, 8, 1, scarf),
            Block(3, 9, 6, 2, fur), Block(5, 9, 2, 2, cream),
            Block(9, 9, 2, 1, fur),
            Block(3, 11, 2, 1, stripe), Block(7, 11, 2, 1, stripe),
        ])
    }()

    static let coin: PixelSprite = {
        let rim = Color(hex: 0xA66F00)
        let gold = Theme.gold
        let shine = Theme.goldLight
        let slot = Color(hex: 0xC98A00)
        return PixelSprite(columns: 8, rows: 8, blocks: [
            Block(2, 0, 4, 1, rim), Block(1, 1, 1, 1, rim), Block(6, 1, 1, 1, rim),
            Block(0, 2, 1, 4, rim), Block(7, 2, 1, 4, rim),
            Block(1, 6, 1, 1, rim), Block(6, 6, 1, 1, rim), Block(2, 7, 4, 1, rim),
            Block(2, 1, 4, 1, gold), Block(1, 2, 6, 4, gold), Block(2, 6, 4, 1, gold),
            Block(2, 2, 1, 2, shine),
            Block(4, 2, 1, 4, slot),
        ])
    }()

    static let cloud = PixelSprite(columns: 10, rows: 4, blocks: [
        Block(2, 0, 4, 1, .white),
        Block(1, 1, 7, 1, .white),
        Block(0, 2, 10, 2, .white),
    ])
}

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
