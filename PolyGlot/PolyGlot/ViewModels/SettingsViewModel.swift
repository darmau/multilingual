import Foundation
import SwiftData
import Observation

@Observable
final class SettingsViewModel {
    var openaiAPIKey: String = ""
    var claudeAPIKey: String = ""
    var geminiAPIKey: String = ""
    var selectedLLMProvider: LLMProvider = .openai
    var selectedTTSProvider: TTSProvider = .appleLocal
    var japaneseFuriganaLevel: JapaneseProficiency = .beginner

    func load(from settings: Settings) {
        openaiAPIKey = settings.openaiAPIKey
        claudeAPIKey = settings.claudeAPIKey
        geminiAPIKey = settings.geminiAPIKey
        selectedLLMProvider = settings.selectedLLMProvider
        selectedTTSProvider = settings.selectedTTSProvider
        japaneseFuriganaLevel = settings.japaneseFuriganaLevel
    }

    func save(to settings: Settings) {
        settings.openaiAPIKey = openaiAPIKey
        settings.claudeAPIKey = claudeAPIKey
        settings.geminiAPIKey = geminiAPIKey
        settings.selectedLLMProvider = selectedLLMProvider
        settings.selectedTTSProvider = selectedTTSProvider
        settings.japaneseFuriganaLevel = japaneseFuriganaLevel
    }
}
