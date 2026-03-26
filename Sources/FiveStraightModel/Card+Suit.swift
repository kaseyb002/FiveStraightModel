import Foundation

extension Card {
    public enum Suit: String, Hashable, Identifiable, CaseIterable, Codable, Sendable {
        case heart = "h"
        case club = "c"
        case diamond = "d"
        case spade = "s"

        public var id: String { rawValue }

        public var emoji: String {
            switch self {
            case .spade: return "♠️"
            case .heart: return "❤️"
            case .club: return "♣️"
            case .diamond: return "♦️"
            }
        }

        public var displayableName: String {
            switch self {
            case .heart: return "Hearts"
            case .club: return "Clubs"
            case .diamond: return "Diamonds"
            case .spade: return "Spades"
            }
        }
    }
}
