import Foundation
import SwiftData

@Model
final class Settings {
    var openaiAPIKey: String
    var claudeAPIKey: String
    var geminiAPIKey: String
    var selectedLLMProviderRaw: String
    var selectedTTSProviderRaw: String
    var japaneseFuriganaLevelRaw: String
    var interfaceLanguageRaw: String

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

    var japaneseFuriganaLevel: JapaneseProficiency {
        get { JapaneseProficiency(rawValue: japaneseFuriganaLevelRaw) ?? .beginner }
        set { japaneseFuriganaLevelRaw = newValue.rawValue }
    }

    var interfaceLanguage: InterfaceLanguage {
        get { InterfaceLanguage(rawValue: interfaceLanguageRaw) ?? .system }
        set { interfaceLanguageRaw = newValue.rawValue }
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

    init(
        openaiAPIKey: String = "",
        claudeAPIKey: String = "",
        geminiAPIKey: String = "",
        selectedLLMProvider: LLMProvider = .openai,
        selectedTTSProvider: TTSProvider = .appleLocal,
        japaneseFuriganaLevel: JapaneseProficiency = .beginner,
        useSystemDictionary: Bool = true,
        interfaceLanguage: InterfaceLanguage = .system
    ) {
        self.openaiAPIKey = openaiAPIKey
        self.claudeAPIKey = claudeAPIKey
        self.geminiAPIKey = geminiAPIKey
        self.selectedLLMProviderRaw = selectedLLMProvider.rawValue
        self.selectedTTSProviderRaw = selectedTTSProvider.rawValue
        self.japaneseFuriganaLevelRaw = japaneseFuriganaLevel.rawValue
        self.useSystemDictionary = useSystemDictionary
        self.interfaceLanguageRaw = interfaceLanguage.rawValue
    }
}
