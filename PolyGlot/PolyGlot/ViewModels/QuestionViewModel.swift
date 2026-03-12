import Foundation
import Observation

@Observable
final class QuestionViewModel {
    var questionText: String = ""
    var isLoading: Bool = false
    var responseText: String = ""
    var errorMessage: String?
    var detectedLanguage: SupportedLanguage?

    private let llmManager = LLMManager()

    private let systemPrompt = "You are a helpful multilingual assistant. Respond in the same language the user used to ask the question. Be concise and educational."

    var canSend: Bool {
        !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    func send(settings: Settings) async {
        let trimmed = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let reply = try await llmManager.sendPrompt(trimmed, systemPrompt: systemPrompt, settings: settings)
            responseText = reply
            detectedLanguage = LanguageDetector.detect(reply)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clear() {
        questionText = ""
        responseText = ""
        errorMessage = nil
        detectedLanguage = nil
    }
}
