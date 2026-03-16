import Foundation

/// Prompt provider for Chinese.
///
/// Chinese is the user's native language and is used only for translations
/// and explanations — never for grammar analysis. The `detailed` and `isInput`
/// parameters are intentionally ignored.
struct ChinesePromptProvider: LanguagePromptProvider {
    let language: SupportedLanguage = .chinese

    func dictionaryBlock(detailed: Bool) -> String {
        """
            "chinese": {
              "word": "对应中文词",
              "definitions": [{"meaning": "释义"}]
            }
        """
    }

    func sentenceBlock(isInput: Bool) -> String {
        """
            "chinese": {
              "translation": "中文翻译（若输入为中文则填null）"
            }
        """
    }
}
