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

    init(
        openaiAPIKey: String = "",
        claudeAPIKey: String = "",
        geminiAPIKey: String = "",
        selectedLLMProvider: LLMProvider = .openai,
        selectedTTSProvider: TTSProvider = .appleLocal,
        japaneseFuriganaLevel: JapaneseProficiency = .beginner
    ) {
        self.openaiAPIKey = openaiAPIKey
        self.claudeAPIKey = claudeAPIKey
        self.geminiAPIKey = geminiAPIKey
        self.selectedLLMProviderRaw = selectedLLMProvider.rawValue
        self.selectedTTSProviderRaw = selectedTTSProvider.rawValue
        self.japaneseFuriganaLevelRaw = japaneseFuriganaLevel.rawValue
    }
}
