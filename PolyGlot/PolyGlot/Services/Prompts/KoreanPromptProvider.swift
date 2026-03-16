import Foundation

/// Prompt provider for Korean.
struct KoreanPromptProvider: LanguagePromptProvider {
    let language: SupportedLanguage = .korean

    func dictionaryBlock(detailed: Bool, nativeLanguage: String) -> String {
        if detailed {
            return """
                "korean": {
                  "word": "Korean word",
                  "reading": "romanization",
                  "definitions": [{"pos": "part of speech", "meaning": "definition in \(nativeLanguage)", "example": "Korean example sentence"}],
                  "etymology": "etymology (in \(nativeLanguage))",
                  "conjugation": "conjugation if applicable, otherwise null"
                }
            """
        } else {
            return """
                "korean": {
                  "word": "Korean word",
                  "reading": "romanization",
                  "definitions": [{"pos": "part of speech", "meaning": "definition in \(nativeLanguage)", "example": "Korean example sentence"}],
                  "etymology": null,
                  "conjugation": null
                }
            """
        }
    }

    func sentenceBlock(isInput: Bool, nativeLanguage: String) -> String {
        let grammarSection = isInput ? """
              "grammar": {
                "structure": "sentence pattern analysis (in \(nativeLanguage))",
                "particles": [{"particle": "은/는", "function": "function explanation in \(nativeLanguage)"}],
                "conjugations": [{"word": "base form", "conjugated": "conjugated form", "type": "conjugation type"}],
                "politeness_level": "politeness level",
                "key_patterns": [{"pattern": "~고 싶다", "meaning": "meaning in \(nativeLanguage)"}]
              }
        """ : """
              "grammar": null
        """
        return """
            "korean": {
              "translation": "Korean translation",
        \(grammarSection)
            }
        """
    }
}
