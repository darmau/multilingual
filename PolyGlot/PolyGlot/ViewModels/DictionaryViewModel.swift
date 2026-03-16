import Foundation
import Observation

@Observable
final class DictionaryViewModel {
    var searchText: String = ""
    var detectedLanguage: SupportedLanguage? = nil
    var manualLanguage: SupportedLanguage? = nil
    var isLoading: Bool = false
    var result: WordAnalysisResult? = nil
    var rawResponse: String? = nil
    var errorMessage: String? = nil

    /// System dictionary lookup result (shown alongside or instead of LLM result).
    var systemDictionaryResult: AppleDictionaryService.DictionaryResult? = nil
    /// Whether to present the system dictionary viewer (iOS).
    var showSystemDictionary: Bool = false

    private let llmManager = LLMManager()
    /// Tracks the current in-flight request so it can be cancelled.
    private var currentTask: Task<Void, Never>?

    /// True when the current error requires the user to configure an API key.
    var isAPIKeyError: Bool {
        guard let msg = errorMessage else { return false }
        return msg == LLMError.missingAPIKey.errorDescription
            || msg == LLMError.noLLMAvailable.errorDescription
    }

    /// True when no LLM is available and we're in offline/dictionary-only mode.
    var isOfflineDictionaryMode: Bool {
        result == nil && systemDictionaryResult != nil
    }

    var effectiveLanguage: SupportedLanguage? {
        manualLanguage ?? detectedLanguage
    }

    /// Auto-detects the language from the current searchText.
    func detectLanguage() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            detectedLanguage = nil
            return
        }
        detectedLanguage = LanguageDetector.detect(searchText)
    }

    /// Cancels any in-flight request and starts a new analysis.
    func analyze(settings: Settings) {
        currentTask?.cancel()
        currentTask = Task { await _analyze(settings: settings) }
    }

    @MainActor
    private func _analyze(settings: Settings) async {
        let word = searchText.trimmingCharacters(in: .whitespaces)
        guard !word.isEmpty else { return }

        // Determine language (auto-detect if no manual override)
        let language: SupportedLanguage
        if let lang = manualLanguage {
            language = lang
        } else if let detected = LanguageDetector.detect(word) {
            detectedLanguage = detected
            language = detected
        } else {
            language = .english
            detectedLanguage = .english
        }

        isLoading = true
        errorMessage = nil
        result = nil
        rawResponse = nil
        systemDictionaryResult = nil

        defer { isLoading = false }

        // Always query system dictionary when enabled
        if settings.useSystemDictionary {
            systemDictionaryResult = AppleDictionaryService.lookup(term: word)
        }

        // Try LLM analysis (Apple Intelligence or cloud API)
        let hasLLM = LLMManager.hasAvailableLLM(settings: settings)

        if hasLLM {
            let prompt = PromptBuilder.dictionaryPrompt(
                word: word,
                inputLanguage: language,
                learningLanguages: settings.learningLanguages,
                nativeLanguage: settings.nativeLanguageName
            )
            let systemPrompt = PromptBuilder.dictionarySystemPrompt

            do {
                let responseText = try await llmManager.sendPrompt(
                    prompt, systemPrompt: systemPrompt, settings: settings)
                guard !Task.isCancelled else { return }
                rawResponse = responseText
                result = parseResult(from: responseText)
                if result == nil {
                    errorMessage = String(localized: "Unable to parse response, please retry.")
                }
            } catch is CancellationError {
                // Silently ignore cancellation
            } catch {
                guard !Task.isCancelled else { return }
                // If we have a system dictionary result, show it with a soft warning
                // instead of a blocking error
                if systemDictionaryResult?.found == true {
                    errorMessage = nil // Don't show error; system dict is enough
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        }
        // If no LLM and no system dictionary found, show a helpful message
        if !hasLLM && result == nil && systemDictionaryResult?.found != true {
            errorMessage = "未配置 AI 服务，且系统词典中未找到该词条。请在「设置」中配置 API Key 以获取完整分析。"
        }
    }

    /// Parses the LLM JSON response into a WordAnalysisResult.
    private func parseResult(from text: String) -> WordAnalysisResult? {
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if jsonString.hasPrefix("```") {
            jsonString = jsonString
                .components(separatedBy: "\n")
                .dropFirst()
                .dropLast()
                .joined(separator: "\n")
        }
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(WordAnalysisResult.self, from: data)
    }

    func reset() {
        currentTask?.cancel()
        searchText = ""
        detectedLanguage = nil
        manualLanguage = nil
        result = nil
        rawResponse = nil
        errorMessage = nil
        systemDictionaryResult = nil
        showSystemDictionary = false
        isLoading = false
    }
}
