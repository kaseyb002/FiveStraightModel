import Foundation
import Testing
@testable import FiveStraightModel

// MARK: - Initialization Tests

@Test func initTwoPlayers() throws {
    let round: Round = try Round.fake()
    #expect(round.playerHands.count == 2)
    #expect(round.playerHands[0].cards.count == 7)
    #expect(round.playerHands[1].cards.count == 7)
    #expect(round.sequencesRequired == 2)
    #expect(round.isComplete == false)
    #expect(round.board.spaces.count == 100)
}

@Test func initThreePlayers() throws {
    let players: [Player] = [
        .fake(id: "p1", name: "Alice", chipColor: .blue),
        .fake(id: "p2", name: "Bob", chipColor: .yellow),
        .fake(id: "p3", name: "Charlie", chipColor: .red),
    ]
    let round: Round = try Round(players: players)
    #expect(round.playerHands.count == 3)
    #expect(round.playerHands[0].cards.count == 6)
    #expect(round.sequencesRequired == 1)
}

@Test func initFourPlayers() throws {
    let players: [Player] = [
        .fake(id: "p1", name: "Alice", chipColor: .blue),
        .fake(id: "p2", name: "Bob", chipColor: .yellow),
        .fake(id: "p3", name: "Charlie", chipColor: .blue),
        .fake(id: "p4", name: "Diana", chipColor: .yellow),
    ]
    let round: Round = try Round(players: players)
    #expect(round.playerHands.count == 4)
    #expect(round.playerHands[0].cards.count == 6)
    #expect(round.sequencesRequired == 2)
}

@Test func initSixPlayersThreeTeams() throws {
    let players: [Player] = [
        .fake(id: "p1", chipColor: .blue),
        .fake(id: "p2", chipColor: .yellow),
        .fake(id: "p3", chipColor: .red),
        .fake(id: "p4", chipColor: .blue),
        .fake(id: "p5", chipColor: .yellow),
        .fake(id: "p6", chipColor: .red),
    ]
    let round: Round = try Round(players: players)
    #expect(round.playerHands[0].cards.count == 5)
    #expect(round.sequencesRequired == 1)
}

@Test func initRejectsInvalidPlayerCount() throws {
    let players: [Player] = [
        .fake(id: "p1", chipColor: .blue),
        .fake(id: "p2", chipColor: .yellow),
        .fake(id: "p3", chipColor: .blue),
        .fake(id: "p4", chipColor: .yellow),
        .fake(id: "p5", chipColor: .blue),
    ]
    #expect(throws: FiveStraightModelError.invalidPlayerCount) {
        try Round(players: players)
    }
}

@Test func initRejectsUnequalTeams() throws {
    let players: [Player] = [
        .fake(id: "p1", chipColor: .blue),
        .fake(id: "p2", chipColor: .yellow),
        .fake(id: "p3", chipColor: .blue),
        .fake(id: "p4", chipColor: .blue),
    ]
    #expect(throws: FiveStraightModelError.unequalTeamSizes) {
        try Round(players: players)
    }
}

@Test func initRejectsSingleTeam() throws {
    let players: [Player] = [
        .fake(id: "p1", chipColor: .blue),
        .fake(id: "p2", chipColor: .blue),
    ]
    #expect(throws: FiveStraightModelError.tooFewTeams) {
        try Round(players: players)
    }
}

// MARK: - Board Tests

@Test func standardBoardHas100Spaces() {
    let board: Board = .standard()
    #expect(board.spaces.count == 100)
}

@Test func standardBoardHasFourFreeCorners() {
    let board: Board = .standard()
    let freeSpaces: [BoardSpace] = board.spaces.filter(\.isFreeSpace)
    #expect(freeSpaces.count == 4)
    #expect(freeSpaces.map(\.id).sorted() == [0, 9, 90, 99])
}

@Test func standardBoardEachCardAppearsTwice() {
    let board: Board = .standard()
    var faceCounts: [String: Int] = [:]
    for space: BoardSpace in board.spaces {
        guard let face: CardFace = space.cardFace else { continue }
        faceCounts[face.id, default: 0] += 1
    }
    for (face, count) in faceCounts {
        #expect(count == 2, "Card face \(face) appears \(count) times, expected 2")
    }
    #expect(faceCounts.count == 48)
}

@Test func standardBoardNoJacksOnBoard() {
    let board: Board = .standard()
    for space: BoardSpace in board.spaces {
        if let face: CardFace = space.cardFace {
            #expect(face.rank != .jack, "Jack found on board at space \(space.id)")
        }
    }
}

// MARK: - Card Tests

@Test func deckHas104Cards() {
    let deck: Deck = Deck()
    #expect(deck.cards.count == 104)
}

@Test func deckHasEightJacks() {
    let deck: Deck = Deck()
    let jacks: [Card] = deck.cards.filter(\.isJack)
    #expect(jacks.count == 8)
    let oneEyed: [Card] = jacks.filter(\.isOneEyedJack)
    let twoEyed: [Card] = jacks.filter(\.isTwoEyedJack)
    #expect(oneEyed.count == 4)
    #expect(twoEyed.count == 4)
}

@Test func cardIDRoundTrip() {
    let card: Card = Card(rank: .ace, suit: .heart, deckNumber: 1)
    #expect(card.id == "ah-1")
    let parsed: Card? = Card(id: "ah-1")
    #expect(parsed?.rank == .ace)
    #expect(parsed?.suit == .heart)
    #expect(parsed?.deckNumber == 1)
}

// MARK: - Play Card Tests

@Test func playRegularCard() throws {
    let deck: Deck = Deck()
    var round: Round = try Round.fake(cookedDeck: deck)

    let playerID: PlayerID = round.currentPlayerID!
    let hand: PlayerHand = round.playerHand(for: playerID)!

    let nonJackCard: CardID? = hand.cards.first { cardID in
        guard let card: Card = round.cardsMap[cardID] else { return false }
        return card.isJack == false
    }
    guard let cardID: CardID = nonJackCard else {
        Issue.record("No non-Jack card in hand")
        return
    }

    let card: Card = round.cardsMap[cardID]!
    let face: CardFace = CardFace(rank: card.rank, suit: card.suit)
    let targetSpaces: [BoardSpace] = round.board.openSpaces(matching: face)
    guard let targetSpace: BoardSpace = targetSpaces.first else {
        Issue.record("No open space for card \(cardID)")
        return
    }

    try round.playCard(cardID: cardID, spaceID: targetSpace.id)

    #expect(round.board.spaces[targetSpace.id].chip != nil)
    #expect(round.currentPlayerID != playerID)
    #expect(round.log.count == 1)
}

@Test func playCardWrongPositionThrows() throws {
    let deck: Deck = Deck()
    var round: Round = try Round.fake(cookedDeck: deck)

    let playerID: PlayerID = round.currentPlayerID!
    let hand: PlayerHand = round.playerHand(for: playerID)!

    let nonJackCard: CardID? = hand.cards.first { cardID in
        guard let card: Card = round.cardsMap[cardID] else { return false }
        return card.isJack == false
    }
    guard let cardID: CardID = nonJackCard else { return }

    #expect(throws: FiveStraightModelError.self) {
        try round.playCard(cardID: cardID, spaceID: 50)
    }
}

@Test func playJackAsRegularCardThrows() throws {
    var deck: Deck = Deck()
    let jackCard: Card = deck.cards.first(where: \.isTwoEyedJack)!
    deck.cards.swapAt(0, deck.cards.firstIndex(of: jackCard)!)

    var round: Round = try Round.fake(cookedDeck: deck)
    let playerID: PlayerID = round.currentPlayerID!
    let hand: PlayerHand = round.playerHand(for: playerID)!

    let jackID: CardID? = hand.cards.first { round.cardsMap[$0]?.isTwoEyedJack == true }
    guard let jid: CardID = jackID else { return }

    #expect(throws: FiveStraightModelError.cardIsAJack) {
        try round.playCard(cardID: jid, spaceID: 1)
    }
}

// MARK: - Two-Eyed Jack Tests

@Test func playTwoEyedJack() throws {
    var deck: Deck = Deck()
    let jackCard: Card = deck.cards.first(where: \.isTwoEyedJack)!
    deck.cards.swapAt(0, deck.cards.firstIndex(of: jackCard)!)

    var round: Round = try Round.fake(cookedDeck: deck)
    let playerID: PlayerID = round.currentPlayerID!
    let hand: PlayerHand = round.playerHand(for: playerID)!

    let jackID: CardID? = hand.cards.first { round.cardsMap[$0]?.isTwoEyedJack == true }
    guard let jid: CardID = jackID else {
        Issue.record("No two-eyed jack in hand")
        return
    }

    let openSpace: BoardSpace = round.board.allOpenSpaces().first!

    try round.playTwoEyedJack(cardID: jid, spaceID: openSpace.id)
    #expect(round.board.spaces[openSpace.id].chip == .blue)
}

// MARK: - One-Eyed Jack Tests

@Test func playOneEyedJackRemovesOpponentChip() throws {
    var deck: Deck = Deck()

    let oneEyedJack: Card = deck.cards.first(where: \.isOneEyedJack)!
    deck.cards.swapAt(0, deck.cards.firstIndex(of: oneEyedJack)!)

    var round: Round = try Round.fake(cookedDeck: deck)

    let targetSpace: BoardSpaceID = 15
    round.board.placeChip(at: targetSpace, color: .yellow)

    let p1ID: PlayerID = round.currentPlayerID!
    let hand: PlayerHand = round.playerHand(for: p1ID)!
    let jackID: CardID? = hand.cards.first { round.cardsMap[$0]?.isOneEyedJack == true }
    guard let jid: CardID = jackID else {
        Issue.record("No one-eyed jack in hand")
        return
    }

    try round.removeChip(cardID: jid, spaceID: targetSpace)
    #expect(round.board.spaces[targetSpace].chip == nil)
}

@Test func cannotRemoveOwnChip() throws {
    var deck: Deck = Deck()
    let oneEyedJack: Card = deck.cards.first(where: \.isOneEyedJack)!
    deck.cards.swapAt(0, deck.cards.firstIndex(of: oneEyedJack)!)

    var round: Round = try Round.fake(cookedDeck: deck)

    let targetSpace: BoardSpaceID = 15
    round.board.placeChip(at: targetSpace, color: .blue)

    let p1ID: PlayerID = round.currentPlayerID!
    let hand: PlayerHand = round.playerHand(for: p1ID)!
    let jackID: CardID? = hand.cards.first { round.cardsMap[$0]?.isOneEyedJack == true }
    guard let jid: CardID = jackID else { return }

    #expect(throws: FiveStraightModelError.cannotRemoveOwnChip) {
        try round.removeChip(cardID: jid, spaceID: targetSpace)
    }
}

// MARK: - Dead Card Tests

@Test func tradeDeadCard() throws {
    let deck: Deck = Deck()
    var round: Round = try Round.fake(cookedDeck: deck)
    let playerID: PlayerID = round.currentPlayerID!
    let hand: PlayerHand = round.playerHand(for: playerID)!

    let nonJackCard: CardID? = hand.cards.first { cardID in
        guard let card: Card = round.cardsMap[cardID] else { return false }
        return card.isJack == false
    }
    guard let cardID: CardID = nonJackCard else { return }

    let card: Card = round.cardsMap[cardID]!
    let face: CardFace = CardFace(rank: card.rank, suit: card.suit)
    let matchingSpaces: [BoardSpace] = round.board.spaces(matching: face)
    for space: BoardSpace in matchingSpaces {
        round.board.placeChip(at: space.id, color: .yellow)
    }

    #expect(round.board.isCardDead(card) == true)

    let handCountBefore: Int = round.playerHand(for: playerID)!.cards.count
    try round.tradeDeadCard(cardID: cardID)

    #expect(round.playerHand(for: playerID)!.cards.count == handCountBefore)
    #expect(round.playerHand(for: playerID)!.cards.contains(cardID) == false)
    #expect(round.hasUsedDeadCardTrade == true)
    #expect(round.currentPlayerID == playerID)
}

// MARK: - Sequence Detection Tests

@Test func detectHorizontalSequence() throws {
    var round: Round = try Round.fake()

    // Place 4 blue chips in a row, the 5th is a free corner
    // Row 0: FREE(0), 2♠(1), 3♠(2), 4♠(3), 5♠(4)
    // FREE at index 0 counts for everyone
    round.board.placeChip(at: 1, color: .blue)
    round.board.placeChip(at: 2, color: .blue)
    round.board.placeChip(at: 3, color: .blue)
    round.board.placeChip(at: 4, color: .blue)

    round.checkForNewSequences(color: .blue, at: 4)

    #expect(round.completedSequences.count == 1)
    #expect(round.completedSequences[0].chipColor == .blue)
    #expect(round.completedSequences[0].spaceIDs.sorted() == [0, 1, 2, 3, 4])
}

@Test func detectVerticalSequence() throws {
    var round: Round = try Round.fake()

    // Column 0: spaces 0, 10, 20, 30, 40
    // Space 0 is FREE corner
    round.board.placeChip(at: 10, color: .blue)
    round.board.placeChip(at: 20, color: .blue)
    round.board.placeChip(at: 30, color: .blue)
    round.board.placeChip(at: 40, color: .blue)

    round.checkForNewSequences(color: .blue, at: 40)

    #expect(round.completedSequences.count == 1)
}

@Test func noSequenceWithMixedColors() throws {
    var round: Round = try Round.fake()

    round.board.placeChip(at: 1, color: .blue)
    round.board.placeChip(at: 2, color: .yellow)
    round.board.placeChip(at: 3, color: .blue)
    round.board.placeChip(at: 4, color: .blue)
    round.board.placeChip(at: 5, color: .blue)

    round.checkForNewSequences(color: .blue, at: 5)

    #expect(round.completedSequences.count == 0)
}

// MARK: - Win Condition Tests

@Test func twoTeamGameNeedsTwoSequences() throws {
    var round: Round = try Round.fake()
    #expect(round.sequencesRequired == 2)

    // First sequence (row 0, columns 0-4)
    round.board.placeChip(at: 1, color: .blue)
    round.board.placeChip(at: 2, color: .blue)
    round.board.placeChip(at: 3, color: .blue)
    round.board.placeChip(at: 4, color: .blue)
    round.checkForNewSequences(color: .blue, at: 4)
    #expect(round.hasTeamWon(.blue) == false)

    // Second sequence (row 0, columns 5-9)
    round.board.placeChip(at: 5, color: .blue)
    round.board.placeChip(at: 6, color: .blue)
    round.board.placeChip(at: 7, color: .blue)
    round.board.placeChip(at: 8, color: .blue)
    round.checkForNewSequences(color: .blue, at: 8)
    #expect(round.hasTeamWon(.blue) == true)
}

@Test func threeTeamGameNeedsOneSequence() throws {
    let players: [Player] = [
        .fake(id: "p1", chipColor: .blue),
        .fake(id: "p2", chipColor: .yellow),
        .fake(id: "p3", chipColor: .red),
    ]
    var round: Round = try Round(players: players)
    #expect(round.sequencesRequired == 1)

    round.board.placeChip(at: 1, color: .blue)
    round.board.placeChip(at: 2, color: .blue)
    round.board.placeChip(at: 3, color: .blue)
    round.board.placeChip(at: 4, color: .blue)
    round.checkForNewSequences(color: .blue, at: 4)
    #expect(round.hasTeamWon(.blue) == true)
}

// MARK: - Cannot Remove From Completed Sequence

@Test func cannotRemoveChipFromCompletedSequence() throws {
    var deck: Deck = Deck()
    let oneEyedJack: Card = deck.cards.first(where: \.isOneEyedJack)!
    deck.cards.swapAt(0, deck.cards.firstIndex(of: oneEyedJack)!)

    var round: Round = try Round.fake(cookedDeck: deck)

    round.board.placeChip(at: 1, color: .yellow)
    round.board.placeChip(at: 2, color: .yellow)
    round.board.placeChip(at: 3, color: .yellow)
    round.board.placeChip(at: 4, color: .yellow)
    round.checkForNewSequences(color: .yellow, at: 4)
    #expect(round.completedSequences.count == 1)

    let p1ID: PlayerID = round.currentPlayerID!
    let hand: PlayerHand = round.playerHand(for: p1ID)!
    let jackID: CardID? = hand.cards.first { round.cardsMap[$0]?.isOneEyedJack == true }
    guard let jid: CardID = jackID else { return }

    #expect(throws: FiveStraightModelError.cannotRemoveFromCompletedSequence) {
        try round.removeChip(cardID: jid, spaceID: 1)
    }
}

// MARK: - Log Trimming

@Test func logTrimsToMaxActions() throws {
    var round: Round = try Round.fake()

    for i: Int in 0..<150 {
        round.log.append(Round.Action(
            playerID: "p1",
            actionType: .playCard(cardId: "fake-\(i)", spaceId: 0),
            timestamp: .now
        ))
        if round.log.count > Round.maxLogActions {
            round.log.removeFirst(round.log.count - Round.maxLogActions)
        }
    }

    #expect(round.log.count == Round.maxLogActions)
}

// MARK: - Full Game Playthrough

@Test func fullGamePlaythrough() throws {
    let deck: Deck = Deck()
    var round: Round = try Round.fake(cookedDeck: deck)

    var moveCount: Int = 0
    let maxMoves: Int = 500

    while round.isComplete == false, moveCount < maxMoves {
        guard let playerID: PlayerID = round.currentPlayerID else { break }

        let moves: [Round.Action.ActionType] = round.validMoves(for: playerID)
        if moves.isEmpty { break }

        let move: Round.Action.ActionType = moves[moveCount % moves.count]

        switch move {
        case .playCard(let cardId, let spaceId):
            try round.playCard(cardID: cardId, spaceID: spaceId)
        case .playTwoEyedJack(let cardId, let spaceId):
            try round.playTwoEyedJack(cardID: cardId, spaceID: spaceId)
        case .removeChip(let cardId, let spaceId):
            try round.removeChip(cardID: cardId, spaceID: spaceId)
        case .tradeDeadCard(let cardId, _):
            try round.tradeDeadCard(cardID: cardId)
        }

        moveCount += 1
    }

    #expect(moveCount > 0)
    #expect(round.log.isEmpty == false)
}

// MARK: - AI Tests

@Test func aiEasyMakesValidMove() throws {
    let deck: Deck = Deck()
    var round: Round = try Round.fake(cookedDeck: deck)

    try round.makeAIMove(difficulty: .easy)

    #expect(round.currentPlayerID == "p2" || round.isComplete)
}

@Test func aiMediumMakesValidMove() throws {
    let deck: Deck = Deck()
    var round: Round = try Round.fake(cookedDeck: deck)

    try round.makeAIMove(difficulty: .medium)

    #expect(round.currentPlayerID == "p2" || round.isComplete)
}

@Test func aiHardMakesValidMove() throws {
    let deck: Deck = Deck()
    var round: Round = try Round.fake(cookedDeck: deck)

    try round.makeAIMove(difficulty: .hard)

    #expect(round.currentPlayerID == "p2" || round.isComplete)
}

@Test func aiPlaysFullGame() throws {
    let deck: Deck = Deck()
    var round: Round = try Round.fake(cookedDeck: deck)

    var moveCount: Int = 0
    let maxMoves: Int = 500

    while round.isComplete == false, moveCount < maxMoves {
        try round.makeAIMove(difficulty: .medium)
        moveCount += 1
    }

    #expect(moveCount > 0)
}

// MARK: - Fake Tests

@Test func roundFakeCreatesValidRound() throws {
    let round: Round = try Round.fake()
    #expect(round.playerHands.count == 2)
    #expect(round.isComplete == false)
    #expect(round.board.spaces.count == 100)
}

@Test func playerFakeCreatesValidPlayer() {
    let player: Player = Player.fake()
    #expect(player.name == "Player")
    #expect(player.chipColor == .blue)
}

@Test func cardFakeCreatesValidCard() {
    let card: Card = Card.fake()
    #expect(card.rank == .ace)
    #expect(card.suit == .heart)
    #expect(card.deckNumber == 1)
}

// MARK: - Codable Tests

@Test func roundIsCodable() throws {
    let round: Round = try Round.fake(cookedDeck: Deck())
    let encoder: JSONEncoder = JSONEncoder()
    let data: Data = try encoder.encode(round)
    let decoder: JSONDecoder = JSONDecoder()
    let decoded: Round = try decoder.decode(Round.self, from: data)
    #expect(decoded == round)
}

@Test func cardIsCodable() throws {
    let card: Card = Card.fake()
    let encoder: JSONEncoder = JSONEncoder()
    let data: Data = try encoder.encode(card)
    let decoder: JSONDecoder = JSONDecoder()
    let decoded: Card = try decoder.decode(Card.self, from: data)
    #expect(decoded == card)
}

// MARK: - Turn Order Tests

@Test func turnAlternatesBetweenPlayers() throws {
    let deck: Deck = Deck()
    var round: Round = try Round.fake(cookedDeck: deck)

    let p1: PlayerID = round.turnOrder[0]
    let p2: PlayerID = round.turnOrder[1]

    #expect(round.currentPlayerID == p1)

    try round.makeAIMove(difficulty: .easy)

    #expect(round.currentPlayerID == p2 || round.isComplete)
}

// MARK: - Hand Size Tests

@Test func handSizesByPlayerCount() {
    #expect(Round.handSize(forPlayerCount: 2) == 7)
    #expect(Round.handSize(forPlayerCount: 3) == 6)
    #expect(Round.handSize(forPlayerCount: 4) == 6)
    #expect(Round.handSize(forPlayerCount: 6) == 5)
    #expect(Round.handSize(forPlayerCount: 8) == 4)
    #expect(Round.handSize(forPlayerCount: 9) == 4)
    #expect(Round.handSize(forPlayerCount: 10) == 3)
    #expect(Round.handSize(forPlayerCount: 12) == 3)
}

// MARK: - Valid Player Counts

@Test func validPlayerCounts() {
    let valid: Set<Int> = [2, 3, 4, 6, 8, 9, 10, 12]
    #expect(Round.validPlayerCounts == valid)
}
