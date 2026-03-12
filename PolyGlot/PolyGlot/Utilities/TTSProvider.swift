import Foundation

enum TTSProvider: String, CaseIterable, Codable, Identifiable {
    case openaiTTS
    case appleLocal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openaiTTS: return "OpenAI TTS"
        case .appleLocal: return "Apple Local"
        }
    }
}
