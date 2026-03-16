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
        .french: FrenchPromptProvider(),
        .spanish: SpanishPromptProvider(),
        .arabic: ArabicPromptProvider(),
        .german: GermanPromptProvider(),
        .portuguese: PortuguesePromptProvider(),
    ]

    /// Returns the prompt provider for a given language.
    static func provider(for language: SupportedLanguage) -> LanguagePromptProvider {
        guard let provider = providers[language] else {
            fatalError("No LanguagePromptProvider registered for \(language)")
        }
        return provider
    }

    /// Returns providers for the specified output languages, preserving order.
    static func outputProviders(for languages: [SupportedLanguage]) -> [LanguagePromptProvider] {
        languages.map { provider(for: $0) }
    }
}
