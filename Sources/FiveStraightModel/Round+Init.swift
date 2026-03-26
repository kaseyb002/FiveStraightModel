import Foundation

extension Round {
    public init(
        id: String = UUID().uuidString,
        started: Date = .now,
        players: [Player],
        cookedDeck: Deck? = nil,
        board: Board = .standard()
    ) throws {
        // Validate player count
        guard Self.validPlayerCounts.contains(players.count) else {
            throw FiveStraightModelError.invalidPlayerCount
        }

        // Validate teams
        let teamGroups: [ChipColor: [Player]] = Dictionary(grouping: players, by: \.chipColor)
        let teamCount: Int = teamGroups.count

        guard teamCount >= 2 else {
            throw FiveStraightModelError.tooFewTeams
        }
        guard teamCount <= 3 else {
            throw FiveStraightModelError.tooManyTeams
        }

        let teamSizes: [Int] = teamGroups.values.map(\.count)
        guard Set(teamSizes).count == 1 else {
            throw FiveStraightModelError.unequalTeamSizes
        }

        self.id = id
        self.started = started
        self.sequencesRequired = teamCount == 2 ? 2 : 1
        self.board = board

        // Setup deck
        let deck: Deck
        if let cookedDeck {
            deck = cookedDeck
        } else {
            var newDeck: Deck = Deck()
            newDeck.shuffle()
            deck = newDeck
        }

        var builtCardsMap: [CardID: Card] = [:]
        for card: Card in deck.cards {
            builtCardsMap[card.id] = card
        }
        self.cardsMap = builtCardsMap

        // Deal cards
        let handSize: Int = Self.handSize(forPlayerCount: players.count)
        var remainingCardIDs: [CardID] = deck.cards.map(\.id)
        var builtPlayerHands: [PlayerHand] = []

        for player: Player in players {
            var hand: [CardID] = []
            for _ in 0..<handSize {
                if remainingCardIDs.isEmpty == false {
                    hand.append(remainingCardIDs.removeFirst())
                }
            }
            builtPlayerHands.append(PlayerHand(player: player, cards: hand))
        }

        self.playerHands = builtPlayerHands
        self.drawPile = remainingCardIDs
        self.discardPile = []

        // Turn order: players alternate team colors around the table
        self.turnOrder = players.map(\.id)
        self.currentTurnIndex = 0
        self.hasUsedDeadCardTrade = false

        self.completedSequences = []
        self.log = []
        self.ended = nil

        self.state = .waitingForPlayer(id: players[0].id)
    }
}
