import Foundation

extension Round {

    // MARK: - Play Card

    /// Play a regular (non-Jack) card and place a chip on a matching board space.
    public mutating func playCard(cardID: CardID, spaceID: BoardSpaceID) throws {
        guard isComplete == false else { throw FiveStraightModelError.gameIsComplete }

        let currentPlayerID: PlayerID = try validateCurrentPlayer()
        let card: Card = try validateCardInHand(cardID: cardID, playerID: currentPlayerID)

        guard card.isJack == false else {
            throw FiveStraightModelError.cardIsAJack
        }

        guard spaceID >= 0, spaceID < board.spaces.count else {
            throw FiveStraightModelError.positionNotFound
        }

        let space: BoardSpace = board.spaces[spaceID]

        guard let face: CardFace = space.cardFace else {
            throw FiveStraightModelError.cannotPlaceOnFreeSpace
        }
        guard face.rank == card.rank, face.suit == card.suit else {
            throw FiveStraightModelError.positionDoesNotMatchCard
        }
        guard space.chip == nil else {
            throw FiveStraightModelError.positionAlreadyOccupied
        }

        let chipColor: ChipColor = chipColor(for: currentPlayerID)
        removeCardFromHand(cardID: cardID, playerID: currentPlayerID)
        discardPile.append(cardID)
        board.placeChip(at: spaceID, color: chipColor)
        drawCard(for: currentPlayerID)

        logAction(playerID: currentPlayerID, actionType: .playCard(cardId: cardID, spaceId: spaceID))

        checkForNewSequences(color: chipColor, at: spaceID)

        if hasTeamWon(chipColor) {
            state = .gameComplete(winningTeam: chipColor)
            ended = .now
        } else {
            advanceToNextPlayer()
        }
    }

    // MARK: - Play Two-Eyed Jack (Wild)

    /// Play a two-eyed Jack to place a chip on any open non-free board space.
    public mutating func playTwoEyedJack(cardID: CardID, spaceID: BoardSpaceID) throws {
        guard isComplete == false else { throw FiveStraightModelError.gameIsComplete }

        let currentPlayerID: PlayerID = try validateCurrentPlayer()
        let card: Card = try validateCardInHand(cardID: cardID, playerID: currentPlayerID)

        guard card.isTwoEyedJack else {
            throw FiveStraightModelError.notATwoEyedJack
        }

        guard spaceID >= 0, spaceID < board.spaces.count else {
            throw FiveStraightModelError.positionNotFound
        }

        let space: BoardSpace = board.spaces[spaceID]

        guard space.isFreeSpace == false else {
            throw FiveStraightModelError.cannotPlaceOnFreeSpace
        }
        guard space.chip == nil else {
            throw FiveStraightModelError.positionAlreadyOccupied
        }

        let chipColor: ChipColor = chipColor(for: currentPlayerID)
        removeCardFromHand(cardID: cardID, playerID: currentPlayerID)
        discardPile.append(cardID)
        board.placeChip(at: spaceID, color: chipColor)
        drawCard(for: currentPlayerID)

        logAction(playerID: currentPlayerID, actionType: .playTwoEyedJack(cardId: cardID, spaceId: spaceID))

        checkForNewSequences(color: chipColor, at: spaceID)

        if hasTeamWon(chipColor) {
            state = .gameComplete(winningTeam: chipColor)
            ended = .now
        } else {
            advanceToNextPlayer()
        }
    }

    // MARK: - Remove Chip (One-Eyed Jack)

    /// Play a one-eyed Jack to remove an opponent's chip from the board.
    public mutating func removeChip(cardID: CardID, spaceID: BoardSpaceID) throws {
        guard isComplete == false else { throw FiveStraightModelError.gameIsComplete }

        let currentPlayerID: PlayerID = try validateCurrentPlayer()
        let card: Card = try validateCardInHand(cardID: cardID, playerID: currentPlayerID)

        guard card.isOneEyedJack else {
            throw FiveStraightModelError.notAOneEyedJack
        }

        guard spaceID >= 0, spaceID < board.spaces.count else {
            throw FiveStraightModelError.positionNotFound
        }

        let space: BoardSpace = board.spaces[spaceID]

        guard let existingChip: ChipColor = space.chip else {
            throw FiveStraightModelError.noChipToRemove
        }

        let playerChipColor: ChipColor = chipColor(for: currentPlayerID)
        guard existingChip != playerChipColor else {
            throw FiveStraightModelError.cannotRemoveOwnChip
        }

        guard space.isPartOfCompletedSequence == false else {
            throw FiveStraightModelError.cannotRemoveFromCompletedSequence
        }

        removeCardFromHand(cardID: cardID, playerID: currentPlayerID)
        discardPile.append(cardID)
        board.removeChip(at: spaceID)
        drawCard(for: currentPlayerID)

        logAction(playerID: currentPlayerID, actionType: .removeChip(cardId: cardID, spaceId: spaceID))

        advanceToNextPlayer()
    }

    // MARK: - Trade Dead Card

    /// Trade in a dead card for a new card from the draw pile. One per turn, before playing.
    public mutating func tradeDeadCard(cardID: CardID) throws {
        guard isComplete == false else { throw FiveStraightModelError.gameIsComplete }

        let currentPlayerID: PlayerID = try validateCurrentPlayer()
        let card: Card = try validateCardInHand(cardID: cardID, playerID: currentPlayerID)

        guard hasUsedDeadCardTrade == false else {
            throw FiveStraightModelError.alreadyTradedDeadCard
        }

        guard board.isCardDead(card) else {
            throw FiveStraightModelError.cardIsNotDead
        }

        guard drawPile.isEmpty == false else {
            throw FiveStraightModelError.drawPileEmpty
        }

        removeCardFromHand(cardID: cardID, playerID: currentPlayerID)
        discardPile.append(cardID)

        let newCardID: CardID = drawPile.removeFirst()
        addCardToHand(cardID: newCardID, playerID: currentPlayerID)

        hasUsedDeadCardTrade = true

        logAction(playerID: currentPlayerID, actionType: .tradeDeadCard(cardId: cardID, newCardId: newCardID))
    }

    // MARK: - Private Helpers

    private func validateCurrentPlayer() throws -> PlayerID {
        guard case .waitingForPlayer(let playerID) = state else {
            throw FiveStraightModelError.notWaitingForPlayerToAct
        }
        return playerID
    }

    private func validateCardInHand(cardID: CardID, playerID: PlayerID) throws -> Card {
        guard let hand: PlayerHand = playerHands.first(where: { $0.player.id == playerID }) else {
            throw FiveStraightModelError.notCurrentPlayer
        }
        guard hand.cards.contains(cardID) else {
            throw FiveStraightModelError.cardNotInHand
        }
        guard let card: Card = cardsMap[cardID] else {
            throw FiveStraightModelError.cardNotInHand
        }
        return card
    }

    private mutating func removeCardFromHand(cardID: CardID, playerID: PlayerID) {
        guard let index: Int = playerHands.firstIndex(where: { $0.player.id == playerID }) else { return }
        playerHands[index].cards.removeAll { $0 == cardID }
    }

    private mutating func addCardToHand(cardID: CardID, playerID: PlayerID) {
        guard let index: Int = playerHands.firstIndex(where: { $0.player.id == playerID }) else { return }
        playerHands[index].cards.append(cardID)
    }

    private mutating func drawCard(for playerID: PlayerID) {
        guard drawPile.isEmpty == false else { return }
        let newCardID: CardID = drawPile.removeFirst()
        addCardToHand(cardID: newCardID, playerID: playerID)
    }

    func chipColor(for playerID: PlayerID) -> ChipColor {
        guard let hand: PlayerHand = playerHands.first(where: { $0.player.id == playerID }) else {
            return .blue
        }
        return hand.player.chipColor
    }

    mutating func advanceToNextPlayer() {
        currentTurnIndex = (currentTurnIndex + 1) % turnOrder.count
        let nextPlayerID: PlayerID = turnOrder[currentTurnIndex]
        hasUsedDeadCardTrade = false
        state = .waitingForPlayer(id: nextPlayerID)
    }

    private mutating func logAction(playerID: PlayerID, actionType: Action.ActionType) {
        let action: Action = Action(playerID: playerID, actionType: actionType, timestamp: .now)
        log.append(action)
        if log.count > Self.maxLogActions {
            log.removeFirst(log.count - Self.maxLogActions)
        }
    }
}
