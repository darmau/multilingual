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

    /// The effective input language: manual override takes precedence, then auto-detected.
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

    /// Sends the word to LLM for analysis.
    func analyze(settings: Settings) async {
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
            // Default to English if detection fails
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
            let responseText = try await llmManager.sendPrompt(prompt, systemPrompt: systemPrompt, settings: settings)
            rawResponse = responseText
            result = parseResult(from: responseText)
            if result == nil {
                errorMessage = "无法解析响应，请重试。"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Parses the LLM JSON response into a WordAnalysisResult.
    private func parseResult(from text: String) -> WordAnalysisResult? {
        // Strip markdown code fences if present
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if jsonString.hasPrefix("```") {
            jsonString = jsonString
                .components(separatedBy: "\n")
                .dropFirst()
                .dropLast()
                .joined(separator: "\n")
        }

        guard let data = jsonString.data(using: .utf8) else { return nil }

        let decoder = JSONDecoder()
        return try? decoder.decode(WordAnalysisResult.self, from: data)
    }

    func reset() {
        searchText = ""
        detectedLanguage = nil
        manualLanguage = nil
        result = nil
        rawResponse = nil
        errorMessage = nil
    }
}
