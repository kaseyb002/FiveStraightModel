import Foundation

extension Round {

    /// Check for newly completed sequences after placing a chip at the given space.
    mutating func checkForNewSequences(color: ChipColor, at placedSpaceID: BoardSpaceID) {
        let row: Int = placedSpaceID / Board.columns
        let col: Int = placedSpaceID % Board.columns

        let directions: [(dr: Int, dc: Int)] = [
            (0, 1),   // horizontal
            (1, 0),   // vertical
            (1, 1),   // diagonal down-right
            (1, -1),  // diagonal down-left
        ]

        for direction in directions {
            // The placed position could be at any index (0-4) within a 5-in-a-row
            for offset: Int in 0..<5 {
                let startRow: Int = row - direction.dr * offset
                let startCol: Int = col - direction.dc * offset
                let endRow: Int = startRow + direction.dr * 4
                let endCol: Int = startCol + direction.dc * 4

                guard startRow >= 0, startRow < Board.rows,
                      startCol >= 0, startCol < Board.columns,
                      endRow >= 0, endRow < Board.rows,
                      endCol >= 0, endCol < Board.columns
                else { continue }

                var spaceIDs: [BoardSpaceID] = []
                var allMatch: Bool = true

                for step: Int in 0..<5 {
                    let r: Int = startRow + direction.dr * step
                    let c: Int = startCol + direction.dc * step
                    let spaceID: BoardSpaceID = r * Board.columns + c
                    let space: BoardSpace = board.spaces[spaceID]

                    let isMatch: Bool = space.isFreeSpace || space.chip == color
                    if isMatch == false {
                        allMatch = false
                        break
                    }
                    spaceIDs.append(spaceID)
                }

                guard allMatch else { continue }

                let sortedIDs: [BoardSpaceID] = spaceIDs.sorted()
                let alreadyExists: Bool = completedSequences.contains {
                    $0.chipColor == color && $0.spaceIDs.sorted() == sortedIDs
                }
                guard alreadyExists == false else { continue }

                let existingLockedByTeam: Set<BoardSpaceID> = Set(
                    completedSequences
                        .filter { $0.chipColor == color }
                        .flatMap(\.spaceIDs)
                )
                let overlapCount: Int = spaceIDs.filter { existingLockedByTeam.contains($0) }.count
                guard overlapCount <= 1 else { continue }

                completedSequences.append(CompletedSequence(chipColor: color, spaceIDs: spaceIDs))
                for spaceID: BoardSpaceID in spaceIDs {
                    board.spaces[spaceID].isPartOfCompletedSequence = true
                }

                break
            }
        }
    }

    func hasTeamWon(_ chipColor: ChipColor) -> Bool {
        let teamSequenceCount: Int = completedSequences.filter { $0.chipColor == chipColor }.count
        return teamSequenceCount >= sequencesRequired
    }
}
