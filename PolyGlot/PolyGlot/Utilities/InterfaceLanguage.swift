import Foundation
import SwiftUI

/// Languages available for the app's user interface.
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

}
