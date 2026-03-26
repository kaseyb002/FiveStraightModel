import Foundation

public typealias BoardSpaceID = Int

public struct BoardSpace: Equatable, Codable, Sendable, Identifiable {
    public let id: BoardSpaceID
    public let row: Int
    public let column: Int
    public let cardFace: CardFace?
    public internal(set) var chip: ChipColor?
    public internal(set) var isPartOfCompletedSequence: Bool

    public var isFreeSpace: Bool { cardFace == nil }

    public init(
        id: BoardSpaceID,
        row: Int,
        column: Int,
        cardFace: CardFace?,
        chip: ChipColor? = nil,
        isPartOfCompletedSequence: Bool = false
    ) {
        self.id = id
        self.row = row
        self.column = column
        self.cardFace = cardFace
        self.chip = chip
        self.isPartOfCompletedSequence = isPartOfCompletedSequence
    }
}
