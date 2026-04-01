import Foundation

public struct Board: Equatable, Codable, Sendable {
    public var spaces: [BoardSpace]

    /// Row and column counts are derived from the maximum `BoardSpace` coordinates (inclusive grid).
    private var gridExtent: (rows: Int, columns: Int) {
        guard spaces.isEmpty == false else { return (0, 0) }
        var maxRow: Int = 0
        var maxCol: Int = 0
        for space in spaces {
            if space.row > maxRow { maxRow = space.row }
            if space.column > maxCol { maxCol = space.column }
        }
        return (maxRow + 1, maxCol + 1)
    }

    public var rows: Int { gridExtent.rows }
    public var columns: Int { gridExtent.columns }
    public var size: Int {
        let extent: (rows: Int, columns: Int) = gridExtent
        return extent.rows * extent.columns
    }

    public init(spaces: [BoardSpace]) {
        self.spaces = spaces
    }

    public func space(at row: Int, column: Int) -> BoardSpace? {
        let id: Int = row * columns + column
        guard id >= 0, id < spaces.count else { return nil }
        return spaces[id]
    }

    public mutating func placeChip(at spaceID: BoardSpaceID, color: ChipColor) {
        spaces[spaceID].chip = color
    }

    public mutating func removeChip(at spaceID: BoardSpaceID) {
        spaces[spaceID].chip = nil
    }

    public func spaces(matching cardFace: CardFace) -> [BoardSpace] {
        spaces.filter { $0.cardFace == cardFace }
    }

    public func openSpaces(matching cardFace: CardFace) -> [BoardSpace] {
        spaces.filter { $0.cardFace == cardFace && $0.chip == nil }
    }

    public func allOpenSpaces() -> [BoardSpace] {
        spaces.filter { $0.isFreeSpace == false && $0.chip == nil }
    }

    public func isCardDead(_ card: Card) -> Bool {
        guard card.isJack == false else { return false }
        let face: CardFace = CardFace(rank: card.rank, suit: card.suit)
        return openSpaces(matching: face).isEmpty
    }

    // MARK: - Standard Board

    public static func standard() -> Board {
        let layout: [String?] = [
            // Row 0
            nil,  "2s", "3s", "4s", "5s", "6s", "7s", "8s", "9s", nil,
            // Row 1
            "6c", "5c", "4c", "3c", "2c", "ah", "kh", "qh", "th", "ts",
            // Row 2
            "7c", "as", "2d", "3d", "4d", "5d", "6d", "7d", "9h", "qs",
            // Row 3
            "8c", "ks", "6c", "5c", "4c", "3c", "2c", "8d", "8h", "ks",
            // Row 4
            "9c", "qs", "7c", "6h", "5h", "4h", "ac", "9d", "7h", "as",
            // Row 5
            "tc", "ts", "8c", "7h", "2h", "3h", "kc", "td", "6h", "2d",
            // Row 6
            "qc", "9s", "9c", "8h", "9h", "th", "qc", "qd", "5h", "3d",
            // Row 7
            "kc", "8s", "tc", "qh", "kh", "ah", "ad", "kd", "4h", "4d",
            // Row 8
            "ac", "7s", "6s", "5s", "4s", "3s", "2s", "2h", "3h", "5d",
            // Row 9
            nil,  "ad", "kd", "qd", "td", "9d", "8d", "7d", "6d", nil,
        ]

        let columnCount: Int = 10
        var spaces: [BoardSpace] = []
        for (index, faceStr) in layout.enumerated() {
            let row: Int = index / columnCount
            let column: Int = index % columnCount
            let cardFace: CardFace? = faceStr.flatMap { CardFace(faceId: $0) }
            spaces.append(BoardSpace(
                id: index,
                row: row,
                column: column,
                cardFace: cardFace
            ))
        }
        return Board(spaces: spaces)
    }
}
