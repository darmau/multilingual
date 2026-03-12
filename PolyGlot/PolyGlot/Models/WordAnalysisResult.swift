import Foundation

// MARK: - Top Level Result

struct WordAnalysisResult: Codable {
    let inputWord: String
    let inputLanguage: String
    let analyses: LanguageAnalyses

    enum CodingKeys: String, CodingKey {
        case inputWord = "input_word"
        case inputLanguage = "input_language"
        case analyses
    }
}

// MARK: - Language Analyses Container

struct LanguageAnalyses: Codable {
    let english: EnglishAnalysis?
    let chinese: ChineseAnalysis?
    let japanese: JapaneseAnalysis?
    let korean: KoreanAnalysis?
}

// MARK: - Per-Language Analysis

struct EnglishAnalysis: Codable {
    let definitions: [EnglishDefinition]
    let phonetic: String?
    let etymology: String?
    let synonyms: [String]?
    let antonyms: [String]?
}

struct EnglishDefinition: Codable {
    let pos: String
    let meaning: String
    let example: String?
}

struct ChineseAnalysis: Codable {
    let word: String
    let definitions: [ChineseDefinition]
}

struct ChineseDefinition: Codable {
    let meaning: String
}

struct JapaneseAnalysis: Codable {
    let word: String
    let reading: String?
    let definitions: [JapaneseDefinition]
    let etymology: String?
    let conjugation: String?
    let synonyms: [String]?
    let antonyms: [String]?
}

struct JapaneseDefinition: Codable {
    let pos: String?
    let meaning: String
    let example: String?
    let exampleReading: String?

    enum CodingKeys: String, CodingKey {
        case pos
        case meaning
        case example
        case exampleReading = "example_reading"
    }
}

struct KoreanAnalysis: Codable {
    let word: String
    let reading: String?
    let definitions: [KoreanDefinition]
    let etymology: String?
    let conjugation: String?
}

struct KoreanDefinition: Codable {
    let pos: String?
    let meaning: String
    let example: String?
}
