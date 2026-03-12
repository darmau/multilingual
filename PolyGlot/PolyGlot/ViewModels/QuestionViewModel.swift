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

    private let systemPrompt = "You are a helpful multilingual assistant. Respond in the same language the user used to ask the question. Be concise and educational."

    var isAPIKeyError: Bool {
        errorMessage == LLMError.missingAPIKey.errorDescription
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

        do {
            let reply = try await llmManager.sendPrompt(prompt, systemPrompt: systemPrompt, settings: settings)
            guard !Task.isCancelled else { return }
            answerText = reply
            answerLanguage = LanguageDetector.detect(reply)
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
