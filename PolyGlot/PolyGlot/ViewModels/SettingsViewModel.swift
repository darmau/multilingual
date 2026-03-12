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
    var useSystemDictionary: Bool = true

    var isTesting: Bool = false
    var testResultMessage: String = ""
    var testResultIsSuccess: Bool = false
    var showTestResult: Bool = false

    private let llmManager = LLMManager()

    func load(from settings: Settings) {
        openaiAPIKey = settings.openaiAPIKey
        claudeAPIKey = settings.claudeAPIKey
        geminiAPIKey = settings.geminiAPIKey
        selectedLLMProvider = settings.selectedLLMProvider
        selectedTTSProvider = settings.selectedTTSProvider
        japaneseFuriganaLevel = settings.japaneseFuriganaLevel
        useSystemDictionary = settings.useSystemDictionary
    }

    func save(to settings: Settings) {
        settings.openaiAPIKey = openaiAPIKey
        settings.claudeAPIKey = claudeAPIKey
        settings.geminiAPIKey = geminiAPIKey
        settings.selectedLLMProvider = selectedLLMProvider
        settings.selectedTTSProvider = selectedTTSProvider
        settings.japaneseFuriganaLevel = japaneseFuriganaLevel
        settings.useSystemDictionary = useSystemDictionary
    }

    func testConnection(settings: Settings) async {
        isTesting = true
        showTestResult = false

        do {
            let reply = try await llmManager.testConnection(settings: settings)
            testResultMessage = "连接成功: \(reply)"
            testResultIsSuccess = true
        } catch {
            testResultMessage = error.localizedDescription
            testResultIsSuccess = false
        }

        isTesting = false
        showTestResult = true
    }
}
