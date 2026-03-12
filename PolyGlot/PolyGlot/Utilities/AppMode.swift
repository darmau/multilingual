import Foundation

enum AppMode: String, CaseIterable, Codable, Identifiable {
    case dictionary
    case sentence
    case translation
    case question

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dictionary: return String(localized: "Dictionary")
        case .sentence: return String(localized: "Sentence Analysis")
        case .translation: return String(localized: "Translation")
        case .question: return String(localized: "Question")
        }
    }

    var systemImage: String {
        switch self {
        case .dictionary: return "book"
        case .sentence: return "text.magnifyingglass"
        case .translation: return "arrow.left.arrow.right"
        case .question: return "questionmark.bubble"
        }
    }
}
