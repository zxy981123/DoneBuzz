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
    /// Builds a sprite from rows of characters, one cell per character; unknown characters are see-through.
    init(art: [String], palette: [Character: Color]) {
        var blocks: [Block] = []
        for (y, row) in art.enumerated() {
            for (x, char) in row.enumerated() {
                if let color = palette[char] { blocks.append(Block(x, y, 1, 1, color)) }
            }
        }
        self.init(columns: art.map(\.count).max() ?? 0, rows: art.count, blocks: blocks)
    }

    /// Where the cat's tail is pointing; cycling left, middle, right, middle makes it wag.
    enum Tail: CaseIterable { case left, middle, right }

    /// The hero: a little orange cat in a blue scarf, with big sparkly eyes and pink cheeks.
    static func cat(tail: Tail = .middle, blinking: Bool = false) -> PixelSprite {
        var art = [
            ".............",
            ".O......O....",
            ".OO....OO....",
            ".OPOSSOPO....",
            "OOOOSSOOOO...",
            "OOOOOOOOOO...",
            "OKWOOOOKWO...",
            "OKKONNOKKO...",
            "ORROCCORRO...",
            ".OOOOOOOO....",
            "..BBBBBB.....",
            "..OCCCCO.....",
            "..SS..SS.....",
        ].map { Array($0) }
        if blinking {
            art[6] = Array("OOOOOOOOOO...")
        }
        // Tail cells, from the base at the cat's hip out to the darker tip.
        let cells: [(Int, Int)] = switch tail {
        case .left: [(8, 11), (9, 11), (10, 10), (10, 9), (11, 8), (11, 7)]
        case .middle: [(8, 11), (9, 11), (10, 10), (11, 9), (11, 8), (12, 7)]
        case .right: [(8, 11), (9, 11), (10, 11), (11, 10), (12, 9), (12, 8)]
        }
        for (index, (x, y)) in cells.enumerated() {
            art[y][x] = index == cells.count - 1 ? "S" : "O"
        }
        return PixelSprite(art: art.map { String($0) }, palette: catPalette)
    }

    private static let catPalette: [Character: Color] = {
        var palette: [Character: Color] = [:]
        palette["O"] = Color(hex: 0xF08A24) // fur
        palette["S"] = Color(hex: 0xC9661A) // stripes, paws and tail tip
        palette["P"] = Color(hex: 0xFFB3C1) // inner ears
        palette["C"] = Color(hex: 0xFFF1DE) // muzzle and belly
        palette["N"] = Color(hex: 0xE5577A) // nose
        palette["R"] = Color(hex: 0xFF9FB0) // cheeks
        palette["B"] = Color(hex: 0x3D7BFF) // scarf
        palette["K"] = Theme.ink // eyes
        palette["W"] = Color.white // eye sparkle
        return palette
    }()

    static let cat = cat()

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
