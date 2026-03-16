import Foundation

/// Central registry mapping each ``SupportedLanguage`` to its ``LanguagePromptProvider``.
///
/// To add a new language, create a conforming provider struct and add one entry
/// to the ``providers`` dictionary.
enum LanguagePromptRegistry {

    private static let providers: [SupportedLanguage: LanguagePromptProvider] = [
        .chinese: ChinesePromptProvider(),
        .english: EnglishPromptProvider(),
        .japanese: JapanesePromptProvider(),
        .korean: KoreanPromptProvider(),
    ]

    /// Returns the prompt provider for a given language.
    static func provider(for language: SupportedLanguage) -> LanguagePromptProvider {
        guard let provider = providers[language] else {
            fatalError("No LanguagePromptProvider registered for \(language)")
        }
        return provider
    }

    /// Returns providers for all languages except the input language,
    /// preserving the `allCases` ordering.
    static func outputProviders(for inputLanguage: SupportedLanguage) -> [LanguagePromptProvider] {
        SupportedLanguage.allCases
            .filter { $0 != inputLanguage }
            .map { provider(for: $0) }
    }
}
