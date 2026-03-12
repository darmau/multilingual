import Foundation

enum SupportedLanguage: String, CaseIterable, Codable, Identifiable {
    case chinese
    case english
    case japanese
    case korean

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chinese: return "中文"
        case .english: return "English"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        }
    }

    var languageCode: String {
        switch self {
        case .chinese: return "zh-Hans"
        case .english: return "en"
        case .japanese: return "ja"
        case .korean: return "ko"
        }
    }

    var locale: Locale {
        switch self {
        case .chinese: return Locale(identifier: "zh_Hans")
        case .english: return Locale(identifier: "en_US")
        case .japanese: return Locale(identifier: "ja_JP")
        case .korean: return Locale(identifier: "ko_KR")
        }
    }
}
