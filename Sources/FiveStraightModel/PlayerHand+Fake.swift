import Foundation

extension PlayerHand {
    public static func fake(
        player: Player = .fake(),
        cards: [CardID] = []
    ) -> PlayerHand {
        PlayerHand(player: player, cards: cards)
    }
}
