import Foundation

/// Prompt provider for Korean.
struct KoreanPromptProvider: LanguagePromptProvider {
    let language: SupportedLanguage = .korean

    func dictionaryBlock(detailed: Bool) -> String {
        if detailed {
            return """
                "korean": {
                  "word": "韩语单词",
                  "reading": "罗马音",
                  "definitions": [{"pos": "품사", "meaning": "中文释义", "example": "韩语例句"}],
                  "etymology": "词源（用中文）",
                  "conjugation": "变形（如适用，否则为null）"
                }
            """
        } else {
            return """
                "korean": {
                  "word": "韩语单词",
                  "reading": "罗马音",
                  "definitions": [{"pos": "품사", "meaning": "中文释义", "example": "韩语例句"}],
                  "etymology": null,
                  "conjugation": null
                }
            """
        }
    }

    func sentenceBlock(isInput: Bool) -> String {
        let grammarSection = isInput ? """
              "grammar": {
                "structure": "문형 분析（用中文说明）",
                "particles": [{"particle": "은/는", "function": "用中文说明"}],
                "conjugations": [{"word": "原形", "conjugated": "变形", "type": "变形类型"}],
                "politeness_level": "敬语等级",
                "key_patterns": [{"pattern": "~고 싶다", "meaning": "中文解释"}]
              }
        """ : """
              "grammar": null
        """
        return """
            "korean": {
              "translation": "韩语翻译",
        \(grammarSection)
            }
        """
    }
}
