import Foundation

public struct Deck: Equatable, Codable, Sendable {
    public var cards: [Card]

    public mutating func shuffle() {
        cards.shuffle()
    }

    /// Two standard 52-card decks (104 cards total).
    public init() {
        var cards: [Card] = []
        for deckNumber: Int in 1...2 {
            for suit: Card.Suit in Card.Suit.allCases {
                for rank: Card.Rank in Card.Rank.allCases {
                    cards.append(Card(rank: rank, suit: suit, deckNumber: deckNumber))
                }
            }
        }
        self.cards = cards
    }

    public init(cards: [Card]) {
        self.cards = cards
    }
}
