import Foundation

public enum FiveStraightModelError: Error, Equatable, Sendable {
    case invalidPlayerCount
    case invalidTeamConfiguration
    case unequalTeamSizes
    case tooFewTeams
    case tooManyTeams
    case notWaitingForPlayerToAct
    case notCurrentPlayer
    case cardNotInHand
    case positionNotFound
    case positionAlreadyOccupied
    case positionDoesNotMatchCard
    case cannotRemoveFromCompletedSequence
    case cannotRemoveOwnChip
    case noChipToRemove
    case notAOneEyedJack
    case notATwoEyedJack
    case cardIsNotDead
    case gameIsComplete
    case drawPileEmpty
    case cardIsAJack
    case alreadyTradedDeadCard
    case cannotPlaceOnFreeSpace
}
