import Foundation

/// Prompt provider for English.
struct EnglishPromptProvider: LanguagePromptProvider {
    let language: SupportedLanguage = .english

    func dictionaryBlock(detailed: Bool) -> String {
        if detailed {
            return """
                "english": {
                  "definitions": [{"pos": "noun/verb/adj/...", "meaning": "中文释义", "example": "English example sentence"}],
                  "phonetic": "IPA notation",
                  "etymology": "词源说明（用中文）",
                  "synonyms": ["word1", "word2"],
                  "antonyms": ["word1", "word2"]
                }
            """
        } else {
            return """
                "english": {
                  "definitions": [{"pos": "noun/verb/adj/...", "meaning": "中文释义", "example": "English example sentence"}],
                  "phonetic": "IPA notation"
                }
            """
        }
    }

    func sentenceBlock(isInput: Bool) -> String {
        let grammarSection = isInput ? """
              "grammar": {
                "structure": "句型分析（用中文说明）",
                "tense": "时态",
                "voice": "语态",
                "clauses": ["从句拆解（每个从句单独一项）"],
                "key_phrases": [{"phrase": "...", "explanation": "中文解释", "grammar_point": "语法点"}]
              }
        """ : """
              "grammar": null
        """
        let translationLine = isInput ? "" : """
              "translation": "英文翻译",
        """
        return """
            "english": {
        \(translationLine)
        \(grammarSection)
            }
        """
    }
}
