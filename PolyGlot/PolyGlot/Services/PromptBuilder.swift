import Foundation

/// Assembles LLM prompts by delegating to per-language ``LanguagePromptProvider`` instances
/// via ``LanguagePromptRegistry``.
struct PromptBuilder {

    // MARK: - Dictionary Mode

    static let dictionarySystemPrompt = """
    You are a multilingual lexicographer. The user will give you a word. Respond in strict JSON format with no extra commentary or markdown code fences.
    """

    /// Builds a user prompt for dictionary word analysis.
    static func dictionaryPrompt(word: String, inputLanguage: SupportedLanguage) -> String {
        let languageName = inputLanguage.promptName
        let inputProvider = LanguagePromptRegistry.provider(for: inputLanguage)
        let outputProviders = LanguagePromptRegistry.outputProviders(for: inputLanguage)

        var blocks = [inputProvider.dictionaryBlock(detailed: true)]
        blocks += outputProviders.map { $0.dictionaryBlock(detailed: false) }
        let analysesBlock = blocks.joined(separator: ",\n")

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

    // MARK: - Sentence Mode

    static let sentenceSystemPrompt = """
    You are a multilingual language teacher and linguist. Analyze sentences with detailed grammar breakdowns. Respond in strict JSON format with no extra commentary or markdown code fences.
    """

    /// Builds a user prompt for sentence grammar analysis.
    static func sentencePrompt(sentence: String, inputLanguage: SupportedLanguage) -> String {
        let languageName = inputLanguage.promptName
        let inputProvider = LanguagePromptRegistry.provider(for: inputLanguage)
        let outputProviders = LanguagePromptRegistry.outputProviders(for: inputLanguage)

        var blocks = [inputProvider.sentenceBlock(isInput: true)]
        blocks += outputProviders.map { $0.sentenceBlock(isInput: false) }
        let analysesBlock = blocks.joined(separator: ",\n")

        return """
        Analyze this \(languageName) sentence: "\(sentence.replacingOccurrences(of: "\"", with: "\\\""))". Return a JSON object with this exact structure:
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

    // MARK: - Translation Mode

    /// Returns the system prompt for translating text between two languages.
    static func translationSystemPrompt(from source: SupportedLanguage, to target: SupportedLanguage) -> String {
        LanguagePromptRegistry.provider(for: target)
            .translationSystemPrompt(from: source)
    }

    // MARK: - Question Mode

    static let questionSystemPrompt = """
    You are a helpful multilingual assistant. Respond in the same language the user used to ask the question. Be concise and educational.
    """
}
