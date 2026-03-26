import Foundation

public enum AIDifficulty: String, Equatable, Codable, Sendable, CaseIterable {
    case easy
    case medium
    case hard
}

public enum AIMove: Equatable, Sendable {
    case playCard(cardID: CardID, spaceID: BoardSpaceID)
    case playTwoEyedJack(cardID: CardID, spaceID: BoardSpaceID)
    case removeChip(cardID: CardID, spaceID: BoardSpaceID)
    case tradeDeadCard(cardID: CardID)

    public func apply(to round: inout Round) throws {
        switch self {
        case .playCard(let cardID, let spaceID):
            try round.playCard(cardID: cardID, spaceID: spaceID)
        case .playTwoEyedJack(let cardID, let spaceID):
            try round.playTwoEyedJack(cardID: cardID, spaceID: spaceID)
        case .removeChip(let cardID, let spaceID):
            try round.removeChip(cardID: cardID, spaceID: spaceID)
        case .tradeDeadCard(let cardID):
            try round.tradeDeadCard(cardID: cardID)
        }
    }
}

public struct AIEngine: Sendable {
    public let difficulty: AIDifficulty

    public init(difficulty: AIDifficulty = .medium) {
        self.difficulty = difficulty
    }

    public func chooseMove(for round: Round, playerID: PlayerID) -> AIMove? {
        guard let hand: PlayerHand = round.playerHand(for: playerID) else { return nil }

        let deadCardIDs: [CardID] = round.deadCards(for: playerID)
        if deadCardIDs.isEmpty == false,
           round.hasUsedDeadCardTrade == false,
           round.drawPile.isEmpty == false {
            return .tradeDeadCard(cardID: deadCardIDs[0])
        }

        switch difficulty {
        case .easy:
            return chooseEasyMove(for: round, hand: hand)
        case .medium:
            return chooseMediumMove(for: round, hand: hand)
        case .hard:
            return chooseHardMove(for: round, hand: hand)
        }
    }

    public func makeMove(on round: inout Round, playerID: PlayerID) throws {
        guard let move: AIMove = chooseMove(for: round, playerID: playerID) else { return }
        try move.apply(to: &round)

        if round.isComplete == false, round.currentPlayerID == playerID {
            guard let followUp: AIMove = chooseMove(for: round, playerID: playerID) else { return }
            try followUp.apply(to: &round)
        }
    }

    // MARK: - Easy: Random valid move

    private func chooseEasyMove(for round: Round, hand: PlayerHand) -> AIMove? {
        var candidates: [AIMove] = []

        for cardID: CardID in hand.cards {
            guard let card: Card = round.cardsMap[cardID] else { continue }

            if card.isTwoEyedJack {
                let openSpaces: [BoardSpace] = round.board.allOpenSpaces()
                if let space: BoardSpace = openSpaces.randomElement() {
                    candidates.append(.playTwoEyedJack(cardID: cardID, spaceID: space.id))
                }
            } else if card.isOneEyedJack {
                let removable: [BoardSpace] = removableOpponentSpaces(
                    round: round,
                    playerChip: hand.player.chipColor
                )
                if let space: BoardSpace = removable.randomElement() {
                    candidates.append(.removeChip(cardID: cardID, spaceID: space.id))
                }
            } else {
                let face: CardFace = CardFace(rank: card.rank, suit: card.suit)
                let openSpaces: [BoardSpace] = round.board.openSpaces(matching: face)
                if let space: BoardSpace = openSpaces.randomElement() {
                    candidates.append(.playCard(cardID: cardID, spaceID: space.id))
                }
            }
        }

        return candidates.randomElement()
    }

    // MARK: - Medium: Basic heuristics

    private func chooseMediumMove(for round: Round, hand: PlayerHand) -> AIMove? {
        let playerChip: ChipColor = hand.player.chipColor
        var scoredMoves: [(move: AIMove, score: Double)] = []

        for cardID: CardID in hand.cards {
            guard let card: Card = round.cardsMap[cardID] else { continue }

            if card.isTwoEyedJack {
                for space: BoardSpace in round.board.allOpenSpaces() {
                    let score: Double = scorePlacement(
                        round: round,
                        spaceID: space.id,
                        chipColor: playerChip,
                        isWild: true
                    )
                    scoredMoves.append((.playTwoEyedJack(cardID: cardID, spaceID: space.id), score))
                }
            } else if card.isOneEyedJack {
                for space: BoardSpace in removableOpponentSpaces(round: round, playerChip: playerChip) {
                    let score: Double = scoreRemoval(round: round, spaceID: space.id, playerChip: playerChip)
                    scoredMoves.append((.removeChip(cardID: cardID, spaceID: space.id), score))
                }
            } else {
                let face: CardFace = CardFace(rank: card.rank, suit: card.suit)
                for space: BoardSpace in round.board.openSpaces(matching: face) {
                    let score: Double = scorePlacement(
                        round: round,
                        spaceID: space.id,
                        chipColor: playerChip,
                        isWild: false
                    )
                    scoredMoves.append((.playCard(cardID: cardID, spaceID: space.id), score))
                }
            }
        }

        guard scoredMoves.isEmpty == false else { return nil }

        scoredMoves.sort { $0.score > $1.score }
        return scoredMoves[0].move
    }

    // MARK: - Hard: Strategic play with blocking

    private func chooseHardMove(for round: Round, hand: PlayerHand) -> AIMove? {
        let playerChip: ChipColor = hand.player.chipColor
        var scoredMoves: [(move: AIMove, score: Double)] = []

        for cardID: CardID in hand.cards {
            guard let card: Card = round.cardsMap[cardID] else { continue }

            if card.isTwoEyedJack {
                for space: BoardSpace in round.board.allOpenSpaces() {
                    var score: Double = scorePlacement(
                        round: round,
                        spaceID: space.id,
                        chipColor: playerChip,
                        isWild: true
                    )
                    score += blockingBonus(round: round, spaceID: space.id, playerChip: playerChip)
                    score -= 2.0
                    scoredMoves.append((.playTwoEyedJack(cardID: cardID, spaceID: space.id), score))
                }
            } else if card.isOneEyedJack {
                for space: BoardSpace in removableOpponentSpaces(round: round, playerChip: playerChip) {
                    var score: Double = scoreRemoval(round: round, spaceID: space.id, playerChip: playerChip)
                    score += blockingRemovalBonus(round: round, spaceID: space.id, playerChip: playerChip)
                    scoredMoves.append((.removeChip(cardID: cardID, spaceID: space.id), score))
                }
            } else {
                let face: CardFace = CardFace(rank: card.rank, suit: card.suit)
                for space: BoardSpace in round.board.openSpaces(matching: face) {
                    var score: Double = scorePlacement(
                        round: round,
                        spaceID: space.id,
                        chipColor: playerChip,
                        isWild: false
                    )
                    score += blockingBonus(round: round, spaceID: space.id, playerChip: playerChip)
                    score += multiDirectionBonus(round: round, spaceID: space.id, chipColor: playerChip)
                    scoredMoves.append((.playCard(cardID: cardID, spaceID: space.id), score))
                }
            }
        }

        guard scoredMoves.isEmpty == false else { return nil }

        scoredMoves.sort { $0.score > $1.score }
        return scoredMoves[0].move
    }

    // MARK: - Scoring Helpers

    private func scorePlacement(
        round: Round,
        spaceID: BoardSpaceID,
        chipColor: ChipColor,
        isWild: Bool
    ) -> Double {
        var score: Double = 0
        let row: Int = spaceID / Board.columns
        let col: Int = spaceID % Board.columns

        let directions: [(dr: Int, dc: Int)] = [(0, 1), (1, 0), (1, 1), (1, -1)]

        for dir in directions {
            let run: Int = countRunInDirection(
                round: round,
                row: row,
                col: col,
                dr: dir.dr,
                dc: dir.dc,
                chipColor: chipColor,
                includePlaced: true
            )

            switch run {
            case 5...: score += 1000
            case 4: score += 50
            case 3: score += 15
            case 2: score += 5
            default: score += 1
            }
        }

        let centerDist: Double = abs(Double(row) - 4.5) + abs(Double(col) - 4.5)
        score += max(0, 5.0 - centerDist * 0.5)

        if isWild { score -= 2.0 }

        return score
    }

    private func scoreRemoval(round: Round, spaceID: BoardSpaceID, playerChip: ChipColor) -> Double {
        var score: Double = 5.0
        let space: BoardSpace = round.board.spaces[spaceID]
        guard let opponentChip: ChipColor = space.chip else { return 0 }

        let row: Int = spaceID / Board.columns
        let col: Int = spaceID % Board.columns
        let directions: [(dr: Int, dc: Int)] = [(0, 1), (1, 0), (1, 1), (1, -1)]

        for dir in directions {
            let run: Int = countRunInDirection(
                round: round,
                row: row,
                col: col,
                dr: dir.dr,
                dc: dir.dc,
                chipColor: opponentChip,
                includePlaced: false
            )
            switch run {
            case 4...: score += 80
            case 3: score += 25
            case 2: score += 8
            default: break
            }
        }

        return score
    }

    private func blockingBonus(round: Round, spaceID: BoardSpaceID, playerChip: ChipColor) -> Double {
        var bonus: Double = 0
        let row: Int = spaceID / Board.columns
        let col: Int = spaceID % Board.columns
        let directions: [(dr: Int, dc: Int)] = [(0, 1), (1, 0), (1, 1), (1, -1)]

        let opponentColors: [ChipColor] = round.teamColors.filter { $0 != playerChip }

        for opponentChip: ChipColor in opponentColors {
            for dir in directions {
                let run: Int = countRunInDirection(
                    round: round,
                    row: row,
                    col: col,
                    dr: dir.dr,
                    dc: dir.dc,
                    chipColor: opponentChip,
                    includePlaced: false
                )
                if run >= 4 { bonus += 40 }
                else if run >= 3 { bonus += 10 }
            }
        }

        return bonus
    }

    private func blockingRemovalBonus(
        round: Round,
        spaceID: BoardSpaceID,
        playerChip: ChipColor
    ) -> Double {
        let space: BoardSpace = round.board.spaces[spaceID]
        guard let opponentChip: ChipColor = space.chip else { return 0 }

        let row: Int = spaceID / Board.columns
        let col: Int = spaceID % Board.columns
        let directions: [(dr: Int, dc: Int)] = [(0, 1), (1, 0), (1, 1), (1, -1)]

        var bonus: Double = 0

        for dir in directions {
            let run: Int = countRunInDirection(
                round: round,
                row: row,
                col: col,
                dr: dir.dr,
                dc: dir.dc,
                chipColor: opponentChip,
                includePlaced: false
            )
            if run >= 4 { bonus += 60 }
            else if run >= 3 { bonus += 15 }
        }

        return bonus
    }

    private func multiDirectionBonus(
        round: Round,
        spaceID: BoardSpaceID,
        chipColor: ChipColor
    ) -> Double {
        let row: Int = spaceID / Board.columns
        let col: Int = spaceID % Board.columns
        let directions: [(dr: Int, dc: Int)] = [(0, 1), (1, 0), (1, 1), (1, -1)]

        var directionsWithRuns: Int = 0
        for dir in directions {
            let run: Int = countRunInDirection(
                round: round,
                row: row,
                col: col,
                dr: dir.dr,
                dc: dir.dc,
                chipColor: chipColor,
                includePlaced: true
            )
            if run >= 2 { directionsWithRuns += 1 }
        }

        return directionsWithRuns >= 2 ? Double(directionsWithRuns) * 3.0 : 0
    }

    /// Count how many consecutive same-color chips (including free spaces)
    /// exist through (row, col) in the given direction.
    private func countRunInDirection(
        round: Round,
        row: Int,
        col: Int,
        dr: Int,
        dc: Int,
        chipColor: ChipColor,
        includePlaced: Bool
    ) -> Int {
        var count: Int = includePlaced ? 1 : 0

        // Forward
        for step: Int in 1..<5 {
            let r: Int = row + dr * step
            let c: Int = col + dc * step
            guard r >= 0, r < Board.rows, c >= 0, c < Board.columns else { break }
            let space: BoardSpace = round.board.spaces[r * Board.columns + c]
            if space.isFreeSpace || space.chip == chipColor {
                count += 1
            } else {
                break
            }
        }

        // Backward
        for step: Int in 1..<5 {
            let r: Int = row - dr * step
            let c: Int = col - dc * step
            guard r >= 0, r < Board.rows, c >= 0, c < Board.columns else { break }
            let space: BoardSpace = round.board.spaces[r * Board.columns + c]
            if space.isFreeSpace || space.chip == chipColor {
                count += 1
            } else {
                break
            }
        }

        return min(count, 5)
    }

    // MARK: - Utilities

    private func removableOpponentSpaces(round: Round, playerChip: ChipColor) -> [BoardSpace] {
        round.board.spaces.filter { space in
            if let chip: ChipColor = space.chip,
               chip != playerChip,
               space.isPartOfCompletedSequence == false {
                return true
            }
            return false
        }
    }
}

// MARK: - Round Extension for AI

extension Round {
    public mutating func makeAIMove(difficulty: AIDifficulty = .medium) throws {
        guard let playerID: PlayerID = currentPlayerID else {
            throw FiveStraightModelError.notWaitingForPlayerToAct
        }
        try AIEngine(difficulty: difficulty).makeMove(on: &self, playerID: playerID)
    }
}
