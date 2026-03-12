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

    private let llmManager = LLMManager()
    /// Tracks the current in-flight request so it can be cancelled.
    private var currentTask: Task<Void, Never>?

    /// The effective input language: manual override takes precedence, then auto-detected.
    /// True when the current error requires the user to configure an API key.
    var isAPIKeyError: Bool {
        errorMessage == LLMError.missingAPIKey.errorDescription
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

        defer { isLoading = false }

        let prompt = PromptBuilder.dictionaryPrompt(word: word, inputLanguage: language)
        let systemPrompt = PromptBuilder.dictionarySystemPrompt

        do {
            let responseText = try await llmManager.sendPrompt(
                prompt, systemPrompt: systemPrompt, settings: settings)
            guard !Task.isCancelled else { return }
            rawResponse = responseText
            result = parseResult(from: responseText)
            if result == nil {
                errorMessage = "无法解析响应，请重试。"
            }
        } catch is CancellationError {
            // Silently ignore cancellation
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
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
        isLoading = false
    }
}
