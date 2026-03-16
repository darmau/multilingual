import Foundation

/// Prompt provider for Japanese.
///
/// Japanese prompts include furigana annotations in `{漢字|かな}` format
/// for all kanji, as required by the app's core rules.
struct JapanesePromptProvider: LanguagePromptProvider {
    let language: SupportedLanguage = .japanese

    func dictionaryBlock(detailed: Bool, nativeLanguage: String) -> String {
        if detailed {
            return """
                "japanese": {
                  "word": "Japanese word (with {漢字|かな} furigana for all kanji)",
                  "reading": "kana reading",
                  "definitions": [{"pos": "part of speech", "meaning": "definition in \(nativeLanguage)", "example": "Japanese example (with {漢字|かな} furigana)", "example_reading": "kana reading of example"}],
                  "etymology": "etymology (in \(nativeLanguage))",
                  "conjugation": "conjugation table if applicable, otherwise null",
                  "synonyms": ["word1"],
                  "antonyms": ["word1"]
                }
            """
        } else {
            return """
                "japanese": {
                  "word": "Japanese word (with {漢字|かな} furigana for all kanji)",
                  "reading": "kana reading",
                  "definitions": [{"pos": "part of speech", "meaning": "definition in \(nativeLanguage)", "example": "Japanese example (with {漢字|かな} furigana)", "example_reading": "kana reading of example"}],
                  "etymology": "etymology (in \(nativeLanguage))",
                  "conjugation": null,
                  "synonyms": [],
                  "antonyms": []
                }
            """
        }
    }

    func sentenceBlock(isInput: Bool, nativeLanguage: String) -> String {
        let grammarSection = isInput ? """
              "grammar": {
                "structure": "sentence pattern analysis (in \(nativeLanguage))",
                "particles": [{"particle": "は", "function": "function explanation in \(nativeLanguage)"}],
                "conjugations": [{"word": "base form", "conjugated": "conjugated form", "type": "conjugation type"}],
                "politeness_level": "politeness level",
                "key_patterns": [{"pattern": "～てしまう", "meaning": "meaning in \(nativeLanguage)", "usage": "usage notes"}]
              }
        """ : """
              "grammar": null
        """
        return """
            "japanese": {
              "translation": "Japanese translation (with {漢字|かな} furigana for all kanji)",
              "translation_reading": "full kana reading of translation",
        \(grammarSection)
            }
        """
    }
}
