import Foundation
import SwiftData

@Model
final class Settings {
    var openaiAPIKey: String
    var claudeAPIKey: String
    var geminiAPIKey: String
    var selectedLLMProviderRaw: String
    var selectedTTSProviderRaw: String
    var interfaceLanguageRaw: String

    /// Comma-separated raw values of SupportedLanguage representing the user's learning targets.
    var learningLanguagesRaw: String

    /// When true, dictionary mode also queries the system dictionary alongside LLM.
    var useSystemDictionary: Bool

    var selectedLLMProvider: LLMProvider {
        get { LLMProvider(rawValue: selectedLLMProviderRaw) ?? .openai }
        set { selectedLLMProviderRaw = newValue.rawValue }
    }

    var selectedTTSProvider: TTSProvider {
        get { TTSProvider(rawValue: selectedTTSProviderRaw) ?? .appleLocal }
        set { selectedTTSProviderRaw = newValue.rawValue }
    }

    var interfaceLanguage: InterfaceLanguage {
        get { InterfaceLanguage(rawValue: interfaceLanguageRaw) ?? .system }
        set { interfaceLanguageRaw = newValue.rawValue }
    }

    /// The languages the user is learning (max 3).
    var learningLanguages: [SupportedLanguage] {
        get {
            learningLanguagesRaw
                .split(separator: ",")
                .compactMap { SupportedLanguage(rawValue: String($0)) }
        }
        set {
            learningLanguagesRaw = newValue.map(\.rawValue).joined(separator: ",")
        }
    }

    /// The native language name for use in LLM prompts (derived from interface language).
    var nativeLanguageName: String {
        interfaceLanguage.promptLanguageName
    }

    /// The SupportedLanguage corresponding to the user's native language, if any.
    var nativeSupportedLanguage: SupportedLanguage? {
        interfaceLanguage.toSupportedLanguage
    }

    /// Returns true when the currently selected LLM provider has a non-empty API key.
    var hasActiveAPIKey: Bool {
        switch selectedLLMProvider {
        case .openai: return !openaiAPIKey.isEmpty
        case .claude: return !claudeAPIKey.isEmpty
        case .gemini: return !geminiAPIKey.isEmpty
        }
    }

    /// Returns true when any LLM provider has a configured API key.
    var hasAnyAPIKey: Bool {
        !openaiAPIKey.isEmpty || !claudeAPIKey.isEmpty || !geminiAPIKey.isEmpty
    }

    /// Default learning languages based on native language.
    static func defaultLearningLanguages(for interfaceLanguage: InterfaceLanguage) -> [SupportedLanguage] {
        let native = interfaceLanguage.toSupportedLanguage
        if native == .english {
            return [.chinese]
        } else {
            return [.english]
        }
    }

    init(
        openaiAPIKey: String = "",
        claudeAPIKey: String = "",
        geminiAPIKey: String = "",
        selectedLLMProvider: LLMProvider = .openai,
        selectedTTSProvider: TTSProvider = .appleLocal,
        useSystemDictionary: Bool = true,
        interfaceLanguage: InterfaceLanguage = .system,
        learningLanguages: [SupportedLanguage]? = nil
    ) {
        self.openaiAPIKey = openaiAPIKey
        self.claudeAPIKey = claudeAPIKey
        self.geminiAPIKey = geminiAPIKey
        self.selectedLLMProviderRaw = selectedLLMProvider.rawValue
        self.selectedTTSProviderRaw = selectedTTSProvider.rawValue
        self.useSystemDictionary = useSystemDictionary
        self.interfaceLanguageRaw = interfaceLanguage.rawValue
        let langs = learningLanguages ?? Settings.defaultLearningLanguages(for: interfaceLanguage)
        self.learningLanguagesRaw = langs.map(\.rawValue).joined(separator: ",")
    }
}
