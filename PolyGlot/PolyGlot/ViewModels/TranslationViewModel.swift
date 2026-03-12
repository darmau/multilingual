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

    /// Translation session configuration for Apple Translation API
    var translationConfiguration: TranslationSession.Configuration?

    private let llmManager = LLMManager()

    var canTranslate: Bool {
        !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isLoading
            && sourceLanguage != targetLanguage
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

    func translateWithLLM(settings: Settings) async {
        let text = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        translatedText = ""

        let systemPrompt = "You are a professional translator. Translate the following text from \(sourceLanguage.displayName) to \(targetLanguage.displayName). Output ONLY the translated text, no explanations."

        do {
            let result = try await llmManager.sendPrompt(text, systemPrompt: systemPrompt, settings: settings)
            translatedText = result.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Local Translation (Apple Translation API)

    func prepareLocalTranslation() {
        let source = Locale.Language(identifier: sourceLanguage.languageCode)
        let target = Locale.Language(identifier: targetLanguage.languageCode)
        translationConfiguration = .init(source: source, target: target)
    }

    func translateWithSession(_ session: TranslationSession) async {
        let text = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        translatedText = ""

        do {
            let response = try await session.translate(text)
            translatedText = response.targetText
        } catch {
            errorMessage = "本地翻译失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func clear() {
        sourceText = ""
        translatedText = ""
        errorMessage = nil
    }
}
