import Foundation

public typealias CardID = String

public struct Card: Equatable, Codable, Identifiable, Hashable, Sendable {
    public let rank: Rank
    public let suit: Suit
    public let deckNumber: Int

    public var id: CardID { "\(rank.id)\(suit.id)-\(deckNumber)" }

    public var faceId: String { "\(rank.id)\(suit.id)" }

    public var isJack: Bool { rank == .jack }

    public var isOneEyedJack: Bool {
        rank == .jack && (suit == .spade || suit == .heart)
    }

    public var isTwoEyedJack: Bool {
        rank == .jack && (suit == .diamond || suit == .club)
    }

    public var debugDescription: String {
        "\(rank.displayValue)\(suit.emoji)"
    }

    public init(rank: Rank, suit: Suit, deckNumber: Int) {
        self.rank = rank
        self.suit = suit
        self.deckNumber = deckNumber
    }

    public init?(id: String) {
        let parts: [Substring] = id.split(separator: "-")
        guard parts.count == 2,
              let deckNum: Int = Int(parts[1]),
              parts[0].count == 2,
              let rankChar: Character = parts[0].first,
              let rank: Rank = Rank(rawValue: String(rankChar)),
              let suitChar: Character = parts[0].last,
              let suit: Suit = Suit(rawValue: String(suitChar))
        else {
            return nil
        }
        self.rank = rank
        self.suit = suit
        self.deckNumber = deckNum
    }
}
