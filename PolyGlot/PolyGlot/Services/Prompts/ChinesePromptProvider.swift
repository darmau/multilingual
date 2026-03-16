import Foundation

/// Prompt provider for Chinese.
///
/// When Chinese is the user's native language, it provides only translations
/// and explanations — no grammar analysis. When it's a learning target,
/// it provides the same structure as other languages.
struct ChinesePromptProvider: LanguagePromptProvider {
    let language: SupportedLanguage = .chinese

    func dictionaryBlock(detailed: Bool, nativeLanguage: String) -> String {
        if detailed {
            return """
                "chinese": {
                  "word": "Chinese word",
                  "definitions": [{"pos": "noun/verb/adj/...", "meaning": "definition in \(nativeLanguage)", "example": "Chinese example sentence"}],
                  "pinyin": "pinyin with tones",
                  "etymology": "etymology in \(nativeLanguage)",
                  "synonyms": ["word1"],
                  "antonyms": ["word1"]
                }
            """
        } else {
            return """
                "chinese": {
                  "word": "corresponding Chinese word",
                  "definitions": [{"meaning": "definition in \(nativeLanguage)"}],
                  "pinyin": "pinyin with tones"
                }
            """
        }
    }

    func sentenceBlock(isInput: Bool, nativeLanguage: String) -> String {
        if isInput {
            return """
                "chinese": {
                  "grammar": {
                    "structure": "sentence structure analysis (in \(nativeLanguage))",
                    "key_phrases": [{"phrase": "...", "explanation": "explanation in \(nativeLanguage)", "grammar_point": "grammar point"}]
                  }
                }
            """
        } else {
            return """
                "chinese": {
                  "translation": "Chinese translation (null if input is Chinese)"
                }
            """
        }
    }
}
