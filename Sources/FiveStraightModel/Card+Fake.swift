import Foundation

extension Card {
    public static func fake(
        rank: Rank = .ace,
        suit: Suit = .heart,
        deckNumber: Int = 1
    ) -> Card {
        Card(rank: rank, suit: suit, deckNumber: deckNumber)
    }
}
