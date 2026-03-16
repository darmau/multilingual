import Foundation

/// Prompt provider for English.
struct EnglishPromptProvider: LanguagePromptProvider {
    let language: SupportedLanguage = .english

    func dictionaryBlock(detailed: Bool, nativeLanguage: String) -> String {
        if detailed {
            return """
                "english": {
                  "definitions": [{"pos": "noun/verb/adj/...", "meaning": "definition in \(nativeLanguage)", "example": "English example sentence"}],
                  "phonetic": "IPA notation",
                  "etymology": "etymology in \(nativeLanguage)",
                  "synonyms": ["word1", "word2"],
                  "antonyms": ["word1", "word2"]
                }
            """
        } else {
            return """
                "english": {
                  "definitions": [{"pos": "noun/verb/adj/...", "meaning": "definition in \(nativeLanguage)", "example": "English example sentence"}],
                  "phonetic": "IPA notation"
                }
            """
        }
    }

    func sentenceBlock(isInput: Bool, nativeLanguage: String) -> String {
        let grammarSection = isInput ? """
              "grammar": {
                "structure": "sentence structure analysis (in \(nativeLanguage))",
                "tense": "tense",
                "voice": "voice",
                "clauses": ["clause breakdown (each clause as separate item)"],
                "key_phrases": [{"phrase": "...", "explanation": "explanation in \(nativeLanguage)", "grammar_point": "grammar point"}]
              }
        """ : """
              "grammar": null
        """
        let translationLine = isInput ? "" : """
              "translation": "English translation",
        """
        return """
            "english": {
        \(translationLine)
        \(grammarSection)
            }
        """
    }
}
