import Foundation

/// Prompt provider for Arabic.
struct ArabicPromptProvider: LanguagePromptProvider {
    let language: SupportedLanguage = .arabic

    func dictionaryBlock(detailed: Bool, nativeLanguage: String) -> String {
        if detailed {
            return """
                "arabic": {
                  "word": "Arabic word",
                  "definitions": [{"pos": "noun/verb/adj/...", "meaning": "definition in \(nativeLanguage)", "example": "Arabic example sentence"}],
                  "transliteration": "romanized pronunciation",
                  "root": "Arabic root letters if applicable",
                  "etymology": "etymology in \(nativeLanguage)",
                  "synonyms": ["word1"],
                  "antonyms": ["word1"],
                  "conjugation": "key conjugation forms if verb, otherwise null"
                }
            """
        } else {
            return """
                "arabic": {
                  "word": "Arabic word",
                  "definitions": [{"pos": "noun/verb/adj/...", "meaning": "definition in \(nativeLanguage)", "example": "Arabic example sentence"}],
                  "transliteration": "romanized pronunciation"
                }
            """
        }
    }

    func sentenceBlock(isInput: Bool, nativeLanguage: String) -> String {
        let grammarSection = isInput ? """
              "grammar": {
                "structure": "sentence structure analysis (in \(nativeLanguage))",
                "key_phrases": [{"phrase": "...", "explanation": "explanation in \(nativeLanguage)", "grammar_point": "grammar point"}]
              }
        """ : """
              "grammar": null
        """
        let translationLine = isInput ? "" : """
              "translation": "Arabic translation",
        """
        return """
            "arabic": {
        \(translationLine)
        \(grammarSection)
            }
        """
    }
}
