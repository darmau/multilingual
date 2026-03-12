import Foundation

enum AppMode: String, CaseIterable, Codable, Identifiable {
    case dictionary
    case sentence
    case translation
    case question

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dictionary: return "词典"
        case .sentence: return "句子分析"
        case .translation: return "翻译"
        case .question: return "提问"
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
