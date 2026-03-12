import Foundation

/// Builds LLM prompts for each app mode.
struct PromptBuilder {

    // MARK: - Dictionary Mode

    static let dictionarySystemPrompt = """
    You are a multilingual lexicographer. The user will give you a word. Respond in strict JSON format with no extra commentary or markdown code fences.
    """

    /// Builds a user prompt for dictionary word analysis.
    /// - Parameters:
    ///   - word: The word entered by the user.
    ///   - inputLanguage: The detected/selected language of the word.
    /// - Returns: A user prompt string requesting structured JSON analysis.
    static func dictionaryPrompt(word: String, inputLanguage: SupportedLanguage) -> String {
        let languageName = inputLanguage.promptName
        let outputLanguages = outputLanguages(for: inputLanguage)
        let analysesBlock = buildAnalysesBlock(inputLanguage: inputLanguage, outputLanguages: outputLanguages)

        return """
        Analyze the \(languageName) word: "\(word)". Return a JSON object with this exact structure:
        {
          "input_word": "\(word)",
          "input_language": "\(inputLanguage.rawValue)",
          "analyses": {
        \(analysesBlock)
          }
        }
        All definitions and etymologies should be written in Chinese (中文). Examples should be in the target language. For Japanese text, include furigana using the format {漢字|かな} for all kanji.
        """
    }

    // MARK: - Private Helpers

    /// Returns the three output languages for a given input language.
    private static func outputLanguages(for input: SupportedLanguage) -> [SupportedLanguage] {
        switch input {
        case .chinese:  return [.english, .japanese, .korean]
        case .english:  return [.chinese, .japanese, .korean]
        case .japanese: return [.chinese, .english, .korean]
        case .korean:   return [.chinese, .english, .japanese]
        }
    }

    /// Builds the JSON template for the "analyses" field.
    private static func buildAnalysesBlock(inputLanguage: SupportedLanguage, outputLanguages: [SupportedLanguage]) -> String {
        var parts: [String] = []

        // The input language gets detailed analysis; output languages vary by type
        let allLanguages = [inputLanguage] + outputLanguages.filter { $0 != inputLanguage }

        for language in allLanguages {
            let isInput = language == inputLanguage
            switch language {
            case .english:
                parts.append(englishBlock(detailed: isInput))
            case .chinese:
                parts.append(chineseBlock())
            case .japanese:
                parts.append(japaneseBlock(detailed: isInput))
            case .korean:
                parts.append(koreanBlock(detailed: isInput))
            }
        }

        return parts.joined(separator: ",\n")
    }

    private static func englishBlock(detailed: Bool) -> String {
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

    private static func chineseBlock() -> String {
        return """
            "chinese": {
              "word": "对应中文词",
              "definitions": [{"meaning": "释义"}]
            }
        """
    }

    private static func japaneseBlock(detailed: Bool) -> String {
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

    private static func koreanBlock(detailed: Bool) -> String {
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
}

// MARK: - SupportedLanguage Extension for Prompts

private extension SupportedLanguage {
    /// Human-readable language name for use in LLM prompts.
    var promptName: String {
        switch self {
        case .chinese:  return "Chinese"
        case .english:  return "English"
        case .japanese: return "Japanese"
        case .korean:   return "Korean"
        }
    }
}
