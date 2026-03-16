import Foundation
import SwiftUI

/// Languages available for the app's user interface.
/// Also serves as the user's native language setting.
/// When `.system` is selected the app follows the device locale.
enum InterfaceLanguage: String, CaseIterable, Codable, Identifiable {
    case system
    case en
    case zhHans
    case zhHant
    case es
    case hi
    case ar
    case pt
    case ru
    case ja
    case de
    case fr
    case ko
    case id

    var id: String { rawValue }

    /// Native display name – always shown in the language's own script so
    /// users can recognise their language regardless of the current UI locale.
    var displayName: String {
        switch self {
        case .system: return String(localized: "Follow System")
        case .en:     return "English"
        case .zhHans: return "简体中文"
        case .zhHant: return "繁體中文"
        case .es:     return "Español"
        case .hi:     return "हिन्दी"
        case .ar:     return "العربية"
        case .pt:     return "Português"
        case .ru:     return "Русский"
        case .ja:     return "日本語"
        case .de:     return "Deutsch"
        case .fr:     return "Français"
        case .ko:     return "한국어"
        case .id:     return "Bahasa Indonesia"
        }
    }

    /// The `Locale` used to override SwiftUI's environment.
    /// Returns `nil` for `.system` so the app uses the device default.
    var locale: Locale? {
        switch self {
        case .system: return nil
        case .en:     return Locale(identifier: "en")
        case .zhHans: return Locale(identifier: "zh-Hans")
        case .zhHant: return Locale(identifier: "zh-Hant")
        case .es:     return Locale(identifier: "es")
        case .hi:     return Locale(identifier: "hi")
        case .ar:     return Locale(identifier: "ar")
        case .pt:     return Locale(identifier: "pt-BR")
        case .ru:     return Locale(identifier: "ru")
        case .ja:     return Locale(identifier: "ja")
        case .de:     return Locale(identifier: "de")
        case .fr:     return Locale(identifier: "fr")
        case .ko:     return Locale(identifier: "ko")
        case .id:     return Locale(identifier: "id")
        }
    }

    /// The language name used in LLM prompts for writing explanations.
    /// For `.system`, resolves based on the device locale.
    var promptLanguageName: String {
        switch self {
        case .system: return Self.resolveSystemPromptLanguageName()
        case .en:     return "English"
        case .zhHans: return "Simplified Chinese"
        case .zhHant: return "Traditional Chinese"
        case .es:     return "Spanish"
        case .hi:     return "Hindi"
        case .ar:     return "Arabic"
        case .pt:     return "Portuguese"
        case .ru:     return "Russian"
        case .ja:     return "Japanese"
        case .de:     return "German"
        case .fr:     return "French"
        case .ko:     return "Korean"
        case .id:     return "Indonesian"
        }
    }

    /// Maps to a SupportedLanguage if this interface language corresponds to one.
    /// Used to determine which languages are "foreign" for the user.
    var toSupportedLanguage: SupportedLanguage? {
        switch self {
        case .zhHans, .zhHant: return .chinese
        case .en:     return .english
        case .ja:     return .japanese
        case .ko:     return .korean
        case .fr:     return .french
        case .es:     return .spanish
        case .ar:     return .arabic
        case .de:     return .german
        case .pt:     return .portuguese
        case .system: return Self.resolveSystemSupportedLanguage()
        case .hi, .ru, .id: return nil
        }
    }

    /// Resolves the system locale's prompt language name.
    private static func resolveSystemPromptLanguageName() -> String {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        switch code {
        case "zh": return "Chinese"
        case "en": return "English"
        case "ja": return "Japanese"
        case "ko": return "Korean"
        case "fr": return "French"
        case "es": return "Spanish"
        case "ar": return "Arabic"
        case "de": return "German"
        case "pt": return "Portuguese"
        case "hi": return "Hindi"
        case "ru": return "Russian"
        case "id": return "Indonesian"
        default:   return "English"
        }
    }

    /// Resolves the system locale to a SupportedLanguage if possible.
    private static func resolveSystemSupportedLanguage() -> SupportedLanguage? {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        switch code {
        case "zh": return .chinese
        case "en": return .english
        case "ja": return .japanese
        case "ko": return .korean
        case "fr": return .french
        case "es": return .spanish
        case "ar": return .arabic
        case "de": return .german
        case "pt": return .portuguese
        default:   return nil
        }
    }
}
