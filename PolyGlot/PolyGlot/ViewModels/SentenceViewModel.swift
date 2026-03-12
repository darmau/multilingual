import Foundation
import Observation

@Observable
final class SentenceViewModel {
    var inputText: String = ""
    var detectedLanguage: SupportedLanguage? = nil
    var manualLanguage: SupportedLanguage? = nil
    var isLoading: Bool = false
    var result: SentenceAnalysisResult? = nil
    var rawResponse: String? = nil
    var errorMessage: String? = nil

    private let llmManager = LLMManager()
    private var currentTask: Task<Void, Never>?

    var isAPIKeyError: Bool {
        errorMessage == LLMError.missingAPIKey.errorDescription
    }

    var effectiveLanguage: SupportedLanguage? {
        manualLanguage ?? detectedLanguage
    }

    func detectLanguage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else {
            detectedLanguage = nil
            return
        }
        detectedLanguage = LanguageDetector.detect(text)
    }

    func analyze(settings: Settings) {
        currentTask?.cancel()
        currentTask = Task { await _analyze(settings: settings) }
    }

    private func _analyze(settings: Settings) async {
        let sentence = inputText.trimmingCharacters(in: .whitespaces)
        guard !sentence.isEmpty else { return }

        let language: SupportedLanguage
        if let lang = manualLanguage {
            language = lang
        } else if let detected = LanguageDetector.detect(sentence) {
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

        let prompt = PromptBuilder.sentencePrompt(sentence: sentence, inputLanguage: language)
        let systemPrompt = PromptBuilder.sentenceSystemPrompt

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

    private func parseResult(from text: String) -> SentenceAnalysisResult? {
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if jsonString.hasPrefix("```") {
            jsonString = jsonString
                .components(separatedBy: "\n")
                .dropFirst()
                .dropLast()
                .joined(separator: "\n")
        }
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(SentenceAnalysisResult.self, from: data)
    }

    func reset() {
        currentTask?.cancel()
        inputText = ""
        detectedLanguage = nil
        manualLanguage = nil
        result = nil
        rawResponse = nil
        errorMessage = nil
        isLoading = false
    }
}
