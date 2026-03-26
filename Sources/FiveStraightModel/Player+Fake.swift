import Foundation

extension Player {
    public static func fake(
        id: PlayerID = UUID().uuidString,
        name: String = "Player",
        imageURL: URL? = nil,
        chipColor: ChipColor = .blue
    ) -> Player {
        Player(id: id, name: name, imageURL: imageURL, chipColor: chipColor)
    }
}
