import Foundation

enum SupportedLanguage: String, CaseIterable, Codable, Identifiable {
    case chinese
    case english
    case japanese
    case korean
    case french
    case spanish
    case arabic
    case german
    case portuguese

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chinese: return "中文"
        case .english: return "English"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .french: return "Français"
        case .spanish: return "Español"
        case .arabic: return "العربية"
        case .german: return "Deutsch"
        case .portuguese: return "Português"
        }
    }

    var languageCode: String {
        switch self {
        case .chinese: return "zh-Hans"
        case .english: return "en"
        case .japanese: return "ja"
        case .korean: return "ko"
        case .french: return "fr"
        case .spanish: return "es"
        case .arabic: return "ar"
        case .german: return "de"
        case .portuguese: return "pt-BR"
        }
    }

    var locale: Locale {
        switch self {
        case .chinese: return Locale(identifier: "zh_Hans")
        case .english: return Locale(identifier: "en_US")
        case .japanese: return Locale(identifier: "ja_JP")
        case .korean: return Locale(identifier: "ko_KR")
        case .french: return Locale(identifier: "fr_FR")
        case .spanish: return Locale(identifier: "es_ES")
        case .arabic: return Locale(identifier: "ar_SA")
        case .german: return Locale(identifier: "de_DE")
        case .portuguese: return Locale(identifier: "pt_BR")
        }
    }

    /// Human-readable language name for use in LLM prompts (always English).
    var promptName: String {
        switch self {
        case .chinese: return "Chinese"
        case .english: return "English"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .french: return "French"
        case .spanish: return "Spanish"
        case .arabic: return "Arabic"
        case .german: return "German"
        case .portuguese: return "Portuguese"
        }
    }

    /// The JSON key used in LLM response analyses objects.
    var jsonKey: String { rawValue }

    /// Whether this language uses right-to-left script.
    var isRTL: Bool { self == .arabic }

    /// Whether this language needs furigana annotations.
    var needsFurigana: Bool { self == .japanese }
}
