import Foundation
import Observation

@Observable
final class QuestionViewModel {
    var questionText: String = ""
    var answerText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    /// The detected language of the AI response, used for TTS.
    var answerLanguage: SupportedLanguage?

    private let llmManager = LLMManager()
    private var currentTask: Task<Void, Never>?

    var isAPIKeyError: Bool {
        guard let msg = errorMessage else { return false }
        return msg == LLMError.missingAPIKey.errorDescription
            || msg == LLMError.noLLMAvailable.errorDescription
    }

    var canSend: Bool {
        !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    func send(settings: Settings) {
        currentTask?.cancel()
        currentTask = Task { await _send(settings: settings) }
    }

    private func _send(settings: Settings) async {
        let prompt = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        answerText = ""
        answerLanguage = nil

        defer { isLoading = false }

        let systemPrompt = PromptBuilder.questionSystemPrompt(nativeLanguage: settings.nativeLanguageName)
        do {
            for try await chunk in llmManager.streamPrompt(prompt, systemPrompt: systemPrompt, settings: settings) {
                guard !Task.isCancelled else { return }
                answerText += chunk
                // Detect language once we have enough text
                if answerLanguage == nil && answerText.count > 10 {
                    answerLanguage = LanguageDetector.detect(answerText)
                }
            }
            // Final language detection on complete response
            if answerLanguage == nil {
                answerLanguage = LanguageDetector.detect(answerText)
            }
        } catch is CancellationError {
            // Silently ignore cancellation
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    func clear() {
        currentTask?.cancel()
        questionText = ""
        answerText = ""
        errorMessage = nil
        answerLanguage = nil
        isLoading = false
    }
}
