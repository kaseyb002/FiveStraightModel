import Foundation

public enum ChipColor: String, Equatable, Codable, CaseIterable, Hashable, Sendable {
    case red
    case yellow
    case blue

    public var displayableName: String {
        switch self {
        case .red: return "Red"
        case .yellow: return "Yellow"
        case .blue: return "Blue"
        }
    }
}
