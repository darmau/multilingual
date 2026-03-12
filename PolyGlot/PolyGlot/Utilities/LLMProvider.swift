import Foundation

enum LLMProvider: String, CaseIterable, Codable, Identifiable {
    case openai
    case claude
    case gemini

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .claude: return "Claude"
        case .gemini: return "Gemini"
        }
    }
}
