import Foundation

extension Card {
    public enum Rank: String, Hashable, Identifiable, CaseIterable, Codable, Sendable {
        case ace = "a"
        case two = "2"
        case three = "3"
        case four = "4"
        case five = "5"
        case six = "6"
        case seven = "7"
        case eight = "8"
        case nine = "9"
        case ten = "t"
        case jack = "j"
        case queen = "q"
        case king = "k"

        public var id: String { rawValue }

        public var displayValue: String {
            switch self {
            case .ace: return "A"
            case .two: return "2"
            case .three: return "3"
            case .four: return "4"
            case .five: return "5"
            case .six: return "6"
            case .seven: return "7"
            case .eight: return "8"
            case .nine: return "9"
            case .ten: return "10"
            case .jack: return "J"
            case .queen: return "Q"
            case .king: return "K"
            }
        }

        public var longDisplayValue: String {
            switch self {
            case .ace: return "Ace"
            case .two: return "Two"
            case .three: return "Three"
            case .four: return "Four"
            case .five: return "Five"
            case .six: return "Six"
            case .seven: return "Seven"
            case .eight: return "Eight"
            case .nine: return "Nine"
            case .ten: return "Ten"
            case .jack: return "Jack"
            case .queen: return "Queen"
            case .king: return "King"
            }
        }

        public static var nonJackCases: [Rank] {
            allCases.filter { $0 != .jack }
        }
    }
}
