import Foundation

public struct CardFace: Equatable, Codable, Identifiable, Hashable, Sendable {
    public let rank: Card.Rank
    public let suit: Card.Suit

    public var id: String { "\(rank.id)\(suit.id)" }

    public init(rank: Card.Rank, suit: Card.Suit) {
        self.rank = rank
        self.suit = suit
    }

    public init?(faceId: String) {
        guard faceId.count == 2,
              let rankChar: Character = faceId.first,
              let rank: Card.Rank = Card.Rank(rawValue: String(rankChar)),
              let suitChar: Character = faceId.last,
              let suit: Card.Suit = Card.Suit(rawValue: String(suitChar))
        else {
            return nil
        }
        self.rank = rank
        self.suit = suit
    }
}
