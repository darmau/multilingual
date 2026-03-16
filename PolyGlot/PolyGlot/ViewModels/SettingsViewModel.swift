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
    var useSystemDictionary: Bool = true
    var interfaceLanguage: InterfaceLanguage = .system
    var learningLanguages: [SupportedLanguage] = [.english]

    var isTesting: Bool = false
    var testResultMessage: String = ""
    var testResultIsSuccess: Bool = false
    var showTestResult: Bool = false

    private let llmManager = LLMManager()

    /// Available languages to add (not already in learning list, not native language).
    var availableLanguagesToAdd: [SupportedLanguage] {
        let native = interfaceLanguage.toSupportedLanguage
        return SupportedLanguage.allCases.filter { lang in
            lang != native && !learningLanguages.contains(lang)
        }
    }

    /// Whether the user can add more learning languages (max 3).
    var canAddMoreLanguages: Bool {
        learningLanguages.count < 3
    }

    func load(from settings: Settings) {
        openaiAPIKey = settings.openaiAPIKey
        claudeAPIKey = settings.claudeAPIKey
        geminiAPIKey = settings.geminiAPIKey
        selectedLLMProvider = settings.selectedLLMProvider
        selectedTTSProvider = settings.selectedTTSProvider
        useSystemDictionary = settings.useSystemDictionary
        interfaceLanguage = settings.interfaceLanguage
        learningLanguages = settings.learningLanguages
        // If learning languages is empty (e.g., first launch after migration), set defaults
        if learningLanguages.isEmpty {
            learningLanguages = Settings.defaultLearningLanguages(for: interfaceLanguage)
        }
    }

    func save(to settings: Settings) {
        settings.openaiAPIKey = openaiAPIKey
        settings.claudeAPIKey = claudeAPIKey
        settings.geminiAPIKey = geminiAPIKey
        settings.selectedLLMProvider = selectedLLMProvider
        settings.selectedTTSProvider = selectedTTSProvider
        settings.useSystemDictionary = useSystemDictionary
        settings.interfaceLanguage = interfaceLanguage
        settings.learningLanguages = learningLanguages
    }

    /// Remove a language from the learning list at the given index.
    func removeLanguage(at index: Int) {
        guard learningLanguages.indices.contains(index) else { return }
        learningLanguages.remove(at: index)
    }

    /// Add a language to the learning list.
    func addLanguage(_ language: SupportedLanguage) {
        guard canAddMoreLanguages, !learningLanguages.contains(language) else { return }
        learningLanguages.append(language)
    }

    /// Called when interfaceLanguage changes to remove conflicts with native language.
    func syncLearningLanguagesWithNative() {
        if let native = interfaceLanguage.toSupportedLanguage {
            learningLanguages.removeAll { $0 == native }
        }
        if learningLanguages.isEmpty {
            learningLanguages = Settings.defaultLearningLanguages(for: interfaceLanguage)
        }
    }

    func testConnection(settings: Settings) async {
        isTesting = true
        showTestResult = false

        do {
            let reply = try await llmManager.testConnection(settings: settings)
            testResultMessage = String(localized: "Connection successful: \(reply)")
            testResultIsSuccess = true
        } catch {
            testResultMessage = error.localizedDescription
            testResultIsSuccess = false
        }

        isTesting = false
        showTestResult = true
    }
}
