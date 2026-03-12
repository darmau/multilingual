import Foundation

enum JapaneseProficiency: String, CaseIterable, Codable, Identifiable {
    case beginner
    case n5
    case n4
    case n3
    case n2
    case n1
    case native

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beginner: return "初学者"
        case .n5: return "N5"
        case .n4: return "N4"
        case .n3: return "N3"
        case .n2: return "N2"
        case .n1: return "N1"
        case .native: return "母语水平"
        }
    }
}
