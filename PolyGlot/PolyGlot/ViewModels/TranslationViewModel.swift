import Foundation
import Observation
import Translation

@Observable
final class TranslationViewModel {
    var sourceText: String = ""
    var translatedText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    var sourceLanguage: SupportedLanguage = .chinese
    var targetLanguage: SupportedLanguage = .english
    var useLocalTranslation: Bool = false

    /// Translation session configuration for Apple Translation API (stored as Any? for availability compatibility)
    var translationConfiguration: Any?

    private let llmManager = LLMManager()
    private var currentTask: Task<Void, Never>?

    var isAPIKeyError: Bool {
        guard let msg = errorMessage else { return false }
        return msg == LLMError.missingAPIKey.errorDescription
            || msg == LLMError.noLLMAvailable.errorDescription
    }

    var canTranslate: Bool {
        !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isLoading
            && sourceLanguage != targetLanguage
    }

    /// Returns true when local translation should be used automatically
    /// (e.g. when no API key is configured and Apple Intelligence is not available).
    @MainActor
    func shouldPreferLocalTranslation(settings: Settings) -> Bool {
        if useLocalTranslation { return true }
        return !LLMManager.hasAvailableLLM(settings: settings)
    }

    func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp

        if !translatedText.isEmpty {
            let tempText = sourceText
            sourceText = translatedText
            translatedText = tempText
        }
    }

    // MARK: - Cloud Translation (LLM)

    func translateWithLLM(settings: Settings) {
        currentTask?.cancel()
        currentTask = Task { await _translateWithLLM(settings: settings) }
    }

    private func _translateWithLLM(settings: Settings) async {
        let text = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        translatedText = ""

        defer { isLoading = false }

        let systemPrompt = "You are a professional translator. Translate the following text from \(sourceLanguage.displayName) to \(targetLanguage.displayName). Output ONLY the translated text, no explanations."

        do {
            let result = try await llmManager.sendPrompt(text, systemPrompt: systemPrompt, settings: settings)
            guard !Task.isCancelled else { return }
            translatedText = result.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch is CancellationError {
            // Silently ignore cancellation
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Local Translation (Apple Translation API)

    @available(macOS 15.0, iOS 18.0, *)
    func prepareLocalTranslation() {
        let source = Locale.Language(identifier: sourceLanguage.languageCode)
        let target = Locale.Language(identifier: targetLanguage.languageCode)
        translationConfiguration = TranslationSession.Configuration(source: source, target: target)
    }

    @available(macOS 15.0, iOS 18.0, *)
    func translateWithSession(_ session: TranslationSession) async {
        let text = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        translatedText = ""

        defer { isLoading = false }

        do {
            let response = try await session.translate(text)
            translatedText = response.targetText
        } catch {
            errorMessage = "本地翻译失败: \(error.localizedDescription)"
        }
    }

    func clear() {
        currentTask?.cancel()
        sourceText = ""
        translatedText = ""
        errorMessage = nil
        isLoading = false
    }
}
