import Foundation

public struct Round: Equatable, Codable, Sendable, Identifiable {

    // MARK: - Constants

    public static let maxLogActions: Int = 100
    public static let validPlayerCounts: Set<Int> = [2, 3, 4, 6, 8, 9, 10, 12]

    // MARK: - Initialized Properties

    public let id: String
    public let started: Date
    public let sequencesRequired: Int

    // MARK: - Game State

    public internal(set) var state: State
    public internal(set) var board: Board
    public internal(set) var playerHands: [PlayerHand]
    public internal(set) var drawPile: [CardID]
    public internal(set) var discardPile: [CardID]
    public internal(set) var cardsMap: [CardID: Card]
    public internal(set) var completedSequences: [CompletedSequence]
    public internal(set) var turnOrder: [PlayerID]
    public internal(set) var currentTurnIndex: Int
    public internal(set) var hasUsedDeadCardTrade: Bool

    // MARK: - Results

    public internal(set) var log: [Action]
    public internal(set) var ended: Date?

    // MARK: - State

    public enum State: Equatable, Codable, Sendable {
        case waitingForPlayer(id: PlayerID)
        case gameComplete(winningTeam: ChipColor)

        public var logValue: String {
            switch self {
            case .waitingForPlayer(let id):
                "Waiting for player \(id)"
            case .gameComplete(let team):
                "\(team.displayableName) team wins!"
            }
        }
    }

    // MARK: - Completed Sequence

    public struct CompletedSequence: Equatable, Codable, Sendable {
        public let chipColor: ChipColor
        public let spaceIDs: [BoardSpaceID]

        public enum CodingKeys: String, CodingKey {
            case chipColor
            case spaceIDs = "spaceIds"
        }

        public init(chipColor: ChipColor, spaceIDs: [BoardSpaceID]) {
            self.chipColor = chipColor
            self.spaceIDs = spaceIDs
        }
    }

    // MARK: - Action

    public struct Action: Equatable, Codable, Sendable {
        public let playerID: PlayerID
        public let actionType: ActionType
        public let timestamp: Date

        public enum ActionType: Equatable, Codable, Sendable {
            case playCard(cardId: CardID, spaceId: BoardSpaceID)
            case playTwoEyedJack(cardId: CardID, spaceId: BoardSpaceID)
            case removeChip(cardId: CardID, spaceId: BoardSpaceID)
            case tradeDeadCard(cardId: CardID, newCardId: CardID)
        }

        public enum CodingKeys: String, CodingKey {
            case playerID = "playerId"
            case actionType
            case timestamp
        }

        public init(
            playerID: PlayerID,
            actionType: ActionType,
            timestamp: Date = .now
        ) {
            self.playerID = playerID
            self.actionType = actionType
            self.timestamp = timestamp
        }
    }

    // MARK: - Hand Size

    public static func handSize(forPlayerCount count: Int) -> Int {
        switch count {
        case 2: return 7
        case 3, 4: return 6
        case 6: return 5
        case 8, 9: return 4
        case 10, 12: return 3
        default: return 3
        }
    }
}
