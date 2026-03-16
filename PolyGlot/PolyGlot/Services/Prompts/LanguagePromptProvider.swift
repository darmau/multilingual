import Foundation

/// Protocol that each language implements to provide mode-specific prompt templates.
///
/// Conforming types supply JSON template blocks for dictionary and sentence analysis,
/// as well as a system prompt for translation. Adding a new language requires only
/// creating a new conforming struct and registering it in ``LanguagePromptRegistry``.
protocol LanguagePromptProvider {
    /// The language this provider handles.
    var language: SupportedLanguage { get }

    // MARK: - Dictionary Mode

    /// Returns the JSON template block for dictionary word analysis.
    /// - Parameters:
    ///   - detailed: `true` when this language is the input language
    ///     (include etymology, synonyms, conjugation, etc.);
    ///     `false` for output languages (abbreviated).
    ///   - nativeLanguage: The user's native language name for writing definitions/explanations.
    func dictionaryBlock(detailed: Bool, nativeLanguage: String) -> String

    // MARK: - Sentence Mode

    /// Returns the JSON template block for sentence grammar analysis.
    /// - Parameters:
    ///   - isInput: `true` when this language is the input language
    ///     (include full grammar breakdown); `false` for output languages
    ///     (translation only, grammar: null).
    ///   - nativeLanguage: The user's native language name for writing explanations.
    func sentenceBlock(isInput: Bool, nativeLanguage: String) -> String

    // MARK: - Translation Mode

    /// Returns the system prompt for translating text into this language.
    /// A default implementation is provided via protocol extension.
    func translationSystemPrompt(from source: SupportedLanguage) -> String
}

// MARK: - Default Implementation

extension LanguagePromptProvider {
    func translationSystemPrompt(from source: SupportedLanguage) -> String {
        "You are a professional translator. Translate the following text from \(source.displayName) to \(language.displayName). Output ONLY the translated text, no explanations."
    }
}
