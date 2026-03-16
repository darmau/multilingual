import Foundation

/// Prompt provider for Portuguese.
struct PortuguesePromptProvider: LanguagePromptProvider {
    let language: SupportedLanguage = .portuguese

    func dictionaryBlock(detailed: Bool, nativeLanguage: String) -> String {
        if detailed {
            return """
                "portuguese": {
                  "word": "Portuguese word",
                  "definitions": [{"pos": "noun/verb/adj/...", "meaning": "definition in \(nativeLanguage)", "example": "Portuguese example sentence"}],
                  "phonetic": "IPA notation",
                  "gender": "masculine/feminine if applicable, otherwise null",
                  "etymology": "etymology in \(nativeLanguage)",
                  "synonyms": ["word1"],
                  "antonyms": ["word1"],
                  "conjugation": "key conjugation forms if verb, otherwise null"
                }
            """
        } else {
            return """
                "portuguese": {
                  "word": "Portuguese word",
                  "definitions": [{"pos": "noun/verb/adj/...", "meaning": "definition in \(nativeLanguage)", "example": "Portuguese example sentence"}],
                  "phonetic": "IPA notation",
                  "gender": "masculine/feminine if applicable, otherwise null"
                }
            """
        }
    }

    func sentenceBlock(isInput: Bool, nativeLanguage: String) -> String {
        let grammarSection = isInput ? """
              "grammar": {
                "structure": "sentence structure analysis (in \(nativeLanguage))",
                "tense": "tense",
                "mood": "mood (indicative/subjunctive/etc.)",
                "key_phrases": [{"phrase": "...", "explanation": "explanation in \(nativeLanguage)", "grammar_point": "grammar point"}]
              }
        """ : """
              "grammar": null
        """
        let translationLine = isInput ? "" : """
              "translation": "Portuguese translation",
        """
        return """
            "portuguese": {
        \(translationLine)
        \(grammarSection)
            }
        """
    }
}
