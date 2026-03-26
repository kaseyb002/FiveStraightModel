import Foundation

public struct PlayerHand: Equatable, Codable, Sendable {
    public let player: Player
    public var cards: [CardID]

    public init(player: Player, cards: [CardID]) {
        self.player = player
        self.cards = cards
    }
}
