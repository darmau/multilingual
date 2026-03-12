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

    private let systemPrompt = "You are a helpful multilingual assistant. Respond in the same language the user used to ask the question. Be concise and educational."

    var canSend: Bool {
        !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    func send(settings: Settings) async {
        let prompt = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        answerText = ""
        answerLanguage = nil

        do {
            let reply = try await llmManager.sendPrompt(prompt, systemPrompt: systemPrompt, settings: settings)
            answerText = reply
            answerLanguage = LanguageDetector.detect(reply)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clear() {
        questionText = ""
        answerText = ""
        errorMessage = nil
        answerLanguage = nil
    }
}
