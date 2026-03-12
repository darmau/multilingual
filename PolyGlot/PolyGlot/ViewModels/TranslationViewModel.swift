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

    // MARK: - Language Auto-Detection

    /// Language detected from the current sourceText; nil if detection failed or text is too short.
    var detectedSourceLanguage: SupportedLanguage? = nil
    /// True when sourceLanguage was set by the user via the Picker rather than auto-detection.
    private(set) var isSourceLanguageManuallyOverridden: Bool = false

    /// True when the current sourceLanguage was set by auto-detection (not manually overridden).
    var isSourceLanguageAutoDetected: Bool {
        detectedSourceLanguage != nil && !isSourceLanguageManuallyOverridden
    }

    // MARK: - Per-Query Model Selection

    /// Per-query LLM override. nil means use the global setting in Settings.
    var selectedLLMProvider: LLMProvider? = nil
    /// Per-query TTS override. nil means use the global setting in Settings.
    var selectedTTSProvider: TTSProvider? = nil

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

    // MARK: - Auto Language Detection

    /// Detects the source language from the current sourceText.
    /// Only updates if the user has not manually overridden the language.
    func detectSourceLanguage() {
        let text = sourceText.trimmingCharacters(in: .whitespaces)
        guard text.count >= 3, !isSourceLanguageManuallyOverridden else { return }
        if let detected = LanguageDetector.detect(text) {
            detectedSourceLanguage = detected
            sourceLanguage = detected
        }
    }

    /// Manually override the source language (e.g. from a Picker selection).
    func overrideSourceLanguage(_ language: SupportedLanguage) {
        sourceLanguage = language
        detectedSourceLanguage = nil
        isSourceLanguageManuallyOverridden = true
    }

    /// Reset source language to auto-detection mode.
    func resetSourceLanguageToAuto() {
        isSourceLanguageManuallyOverridden = false
        detectedSourceLanguage = nil
        detectSourceLanguage()
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
            for try await chunk in llmManager.streamPrompt(text, systemPrompt: systemPrompt, settings: settings, overrideProvider: selectedLLMProvider) {
                guard !Task.isCancelled else { return }
                translatedText += chunk
            }
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
        detectedSourceLanguage = nil
        isSourceLanguageManuallyOverridden = false
    }
}
