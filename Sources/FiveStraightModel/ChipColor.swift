import Foundation

public enum ChipColor: String, Equatable, Codable, CaseIterable, Hashable, Sendable {
    case blue
    case green
    case red

    public var displayableName: String {
        switch self {
        case .blue: return "Blue"
        case .green: return "Green"
        case .red: return "Red"
        }
    }
}
