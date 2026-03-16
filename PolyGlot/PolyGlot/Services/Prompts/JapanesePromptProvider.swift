import Foundation

/// Prompt provider for Japanese.
///
/// Japanese prompts include furigana annotations in `{漢字|かな}` format
/// for all kanji, as required by the app's core rules.
struct JapanesePromptProvider: LanguagePromptProvider {
    let language: SupportedLanguage = .japanese

    func dictionaryBlock(detailed: Bool) -> String {
        if detailed {
            return """
                "japanese": {
                  "word": "日语单词（含{漢字|かな}格式注音）",
                  "reading": "假名读音",
                  "definitions": [{"pos": "品词", "meaning": "中文释义", "example": "日语例句（含{漢字|かな}注音）", "example_reading": "例句假名读音"}],
                  "etymology": "词源（用中文）",
                  "conjugation": "动词/形容词变形表（如适用，否则为null）",
                  "synonyms": ["word1"],
                  "antonyms": ["word1"]
                }
            """
        } else {
            return """
                "japanese": {
                  "word": "日语单词（含{漢字|かな}格式注音）",
                  "reading": "假名读音",
                  "definitions": [{"pos": "品词", "meaning": "中文释义", "example": "日语例句（含{漢字|かな}注音）", "example_reading": "例句假名读音"}],
                  "etymology": "词源（用中文）",
                  "conjugation": null,
                  "synonyms": [],
                  "antonyms": []
                }
            """
        }
    }

    func sentenceBlock(isInput: Bool) -> String {
        let grammarSection = isInput ? """
              "grammar": {
                "structure": "文型分析（用中文说明）",
                "particles": [{"particle": "は", "function": "用中文说明作用"}],
                "conjugations": [{"word": "原形", "conjugated": "活用形", "type": "活用类型"}],
                "politeness_level": "敬语等级",
                "key_patterns": [{"pattern": "～てしまう", "meaning": "中文解释", "usage": "用法说明"}]
              }
        """ : """
              "grammar": null
        """
        return """
            "japanese": {
              "translation": "日语翻译（含{漢字|かな}注音）",
              "translation_reading": "翻译的假名全文注音",
        \(grammarSection)
            }
        """
    }
}
