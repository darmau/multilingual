import Foundation

/// Prompt provider for German.
struct GermanPromptProvider: LanguagePromptProvider {
    let language: SupportedLanguage = .german

    func dictionaryBlock(detailed: Bool, nativeLanguage: String) -> String {
        if detailed {
            return """
                "german": {
                  "word": "German word",
                  "definitions": [{"pos": "noun/verb/adj/...", "meaning": "definition in \(nativeLanguage)", "example": "German example sentence"}],
                  "phonetic": "IPA notation",
                  "gender": "masculine/feminine/neuter if applicable, otherwise null",
                  "etymology": "etymology in \(nativeLanguage)",
                  "synonyms": ["word1"],
                  "antonyms": ["word1"],
                  "conjugation": "key conjugation/declension forms if applicable, otherwise null"
                }
            """
        } else {
            return """
                "german": {
                  "word": "German word",
                  "definitions": [{"pos": "noun/verb/adj/...", "meaning": "definition in \(nativeLanguage)", "example": "German example sentence"}],
                  "phonetic": "IPA notation",
                  "gender": "masculine/feminine/neuter if applicable, otherwise null"
                }
            """
        }
    }

    func sentenceBlock(isInput: Bool, nativeLanguage: String) -> String {
        let grammarSection = isInput ? """
              "grammar": {
                "structure": "sentence structure analysis (in \(nativeLanguage))",
                "tense": "tense",
                "case_usage": "case usage explanation",
                "key_phrases": [{"phrase": "...", "explanation": "explanation in \(nativeLanguage)", "grammar_point": "grammar point"}]
              }
        """ : """
              "grammar": null
        """
        let translationLine = isInput ? "" : """
              "translation": "German translation",
        """
        return """
            "german": {
        \(translationLine)
        \(grammarSection)
            }
        """
    }
}
