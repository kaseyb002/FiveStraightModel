import Foundation

extension Round {
    public static func fake(
        id: String = UUID().uuidString,
        started: Date = .now,
        players: [Player] = [
            .fake(id: "p1", name: "Player 1", chipColor: .blue),
            .fake(id: "p2", name: "Player 2", chipColor: .yellow),
        ],
        cookedDeck: Deck? = nil,
        board: Board = .standard()
    ) throws -> Round {
        try Round(
            id: id,
            started: started,
            players: players,
            cookedDeck: cookedDeck,
            board: board
        )
    }
}
