import Foundation

extension Round {

    public var isComplete: Bool {
        if case .gameComplete = state { return true }
        return false
    }

    public var currentPlayerID: PlayerID? {
        if case .waitingForPlayer(let id) = state { return id }
        return nil
    }

    public var winningTeam: ChipColor? {
        if case .gameComplete(let team) = state { return team }
        return nil
    }

    public func playerHand(for playerID: PlayerID) -> PlayerHand? {
        playerHands.first { $0.player.id == playerID }
    }

    public var teamColors: Set<ChipColor> {
        Set(playerHands.map(\.player.chipColor))
    }

    public func sequenceCount(for chipColor: ChipColor) -> Int {
        completedSequences.filter { $0.chipColor == chipColor }.count
    }

    public func card(for cardID: CardID) -> Card? {
        cardsMap[cardID]
    }

    /// All valid moves the current player can make (excluding dead card trades).
    public func validMoves(for playerID: PlayerID) -> [Action.ActionType] {
        guard let hand: PlayerHand = playerHand(for: playerID) else { return [] }

        let playerChip: ChipColor = hand.player.chipColor
        var moves: [Action.ActionType] = []

        for cardID: CardID in hand.cards {
            guard let card: Card = cardsMap[cardID] else { continue }

            if card.isTwoEyedJack {
                for space: BoardSpace in board.allOpenSpaces() {
                    moves.append(.playTwoEyedJack(cardId: cardID, spaceId: space.id))
                }
            } else if card.isOneEyedJack {
                for space: BoardSpace in board.spaces {
                    if let chip: ChipColor = space.chip,
                       chip != playerChip,
                       space.isPartOfCompletedSequence == false {
                        moves.append(.removeChip(cardId: cardID, spaceId: space.id))
                    }
                }
            } else {
                let face: CardFace = CardFace(rank: card.rank, suit: card.suit)
                for space: BoardSpace in board.openSpaces(matching: face) {
                    moves.append(.playCard(cardId: cardID, spaceId: space.id))
                }
            }
        }

        return moves
    }

    /// Cards in the player's hand that are dead (both board spaces occupied).
    public func deadCards(for playerID: PlayerID) -> [CardID] {
        guard let hand: PlayerHand = playerHand(for: playerID) else { return [] }
        return hand.cards.filter { cardID in
            guard let card: Card = cardsMap[cardID] else { return false }
            return board.isCardDead(card)
        }
    }
}
