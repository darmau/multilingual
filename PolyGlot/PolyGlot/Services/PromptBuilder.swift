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

    // MARK: - Sentence Mode

    static let sentenceSystemPrompt = """
    You are a multilingual language teacher and linguist. Analyze sentences with detailed grammar breakdowns. Respond in strict JSON format with no extra commentary or markdown code fences.
    """

    /// Builds a user prompt for sentence grammar analysis.
    static func sentencePrompt(sentence: String, inputLanguage: SupportedLanguage) -> String {
        let languageName = inputLanguage.promptName
        let analysesBlock = buildSentenceAnalysesBlock(inputLanguage: inputLanguage)

        return """
        Analyze this \(languageName) sentence: "\(sentence)". Return a JSON object with this exact structure:
        {
          "input_sentence": "\(sentence.replacingOccurrences(of: "\"", with: "\\\""))",
          "input_language": "\(inputLanguage.rawValue)",
          "analyses": {
        \(analysesBlock)
          }
        }
        All grammar explanations and meanings must be written in Chinese (中文). Translations should be accurate and natural. For Japanese text (translations and readings), always include furigana using the format {漢字|かな} for all kanji.
        """
    }

    private static func buildSentenceAnalysesBlock(inputLanguage: SupportedLanguage) -> String {
        let allLanguages: [SupportedLanguage]
        switch inputLanguage {
        case .chinese:  allLanguages = [.chinese, .english, .japanese, .korean]
        case .english:  allLanguages = [.english, .chinese, .japanese, .korean]
        case .japanese: allLanguages = [.japanese, .chinese, .english, .korean]
        case .korean:   allLanguages = [.korean, .chinese, .english, .japanese]
        }

        let parts = allLanguages.map { lang -> String in
            let isInput = lang == inputLanguage
            switch lang {
            case .chinese:
                return sentenceChineseBlock()
            case .english:
                return sentenceEnglishBlock(isInput: isInput)
            case .japanese:
                return sentenceJapaneseBlock(isInput: isInput)
            case .korean:
                return sentenceKoreanBlock(isInput: isInput)
            }
        }
        return parts.joined(separator: ",\n")
    }

    private static func sentenceChineseBlock() -> String {
        """
            "chinese": {
              "translation": "中文翻译（若输入为中文则填null）"
            }
        """
    }

    private static func sentenceEnglishBlock(isInput: Bool) -> String {
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

    private static func sentenceJapaneseBlock(isInput: Bool) -> String {
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

    private static func sentenceKoreanBlock(isInput: Bool) -> String {
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
