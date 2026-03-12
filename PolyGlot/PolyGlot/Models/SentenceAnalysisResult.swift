import Foundation

// MARK: - Top Level

struct SentenceAnalysisResult: Codable {
    let inputSentence: String
    let inputLanguage: String
    let analyses: SentenceLanguageAnalyses

    enum CodingKeys: String, CodingKey {
        case inputSentence = "input_sentence"
        case inputLanguage = "input_language"
        case analyses
    }
}

// MARK: - Analyses Container

struct SentenceLanguageAnalyses: Codable {
    let english: EnglishSentenceAnalysis?
    let chinese: ChineseSentenceAnalysis?
    let japanese: JapaneseSentenceAnalysis?
    let korean: KoreanSentenceAnalysis?
}

// MARK: - Chinese (translation only)

struct ChineseSentenceAnalysis: Codable {
    let translation: String
}

// MARK: - English

struct EnglishSentenceAnalysis: Codable {
    let translation: String?
    let grammar: EnglishGrammar?
}

struct EnglishGrammar: Codable {
    let structure: String?
    let tense: String?
    let voice: String?
    let clauses: [String]?
    let keyPhrases: [EnglishKeyPhrase]?

    enum CodingKeys: String, CodingKey {
        case structure, tense, voice, clauses
        case keyPhrases = "key_phrases"
    }
}

struct EnglishKeyPhrase: Codable {
    let phrase: String
    let explanation: String
    let grammarPoint: String?

    enum CodingKeys: String, CodingKey {
        case phrase, explanation
        case grammarPoint = "grammar_point"
    }
}

// MARK: - Japanese

struct JapaneseSentenceAnalysis: Codable {
    let translation: String
    let translationReading: String?
    let grammar: JapaneseGrammar?

    enum CodingKeys: String, CodingKey {
        case translation
        case translationReading = "translation_reading"
        case grammar
    }
}

struct JapaneseGrammar: Codable {
    let structure: String?
    let particles: [JapaneseParticle]?
    let conjugations: [Conjugation]?
    let politenessLevel: String?
    let keyPatterns: [JapaneseKeyPattern]?

    enum CodingKeys: String, CodingKey {
        case structure, particles, conjugations
        case politenessLevel = "politeness_level"
        case keyPatterns = "key_patterns"
    }
}

struct JapaneseParticle: Codable {
    let particle: String
    let function: String
}

struct JapaneseKeyPattern: Codable {
    let pattern: String
    let meaning: String
    let usage: String?
}

// MARK: - Korean

struct KoreanSentenceAnalysis: Codable {
    let translation: String
    let grammar: KoreanGrammar?
}

struct KoreanGrammar: Codable {
    let structure: String?
    let particles: [KoreanParticle]?
    let conjugations: [Conjugation]?
    let politenessLevel: String?
    let keyPatterns: [KoreanKeyPattern]?

    enum CodingKeys: String, CodingKey {
        case structure, particles, conjugations
        case politenessLevel = "politeness_level"
        case keyPatterns = "key_patterns"
    }
}

struct KoreanParticle: Codable {
    let particle: String
    let function: String
}

struct KoreanKeyPattern: Codable {
    let pattern: String
    let meaning: String
}

// MARK: - Shared

struct Conjugation: Codable {
    let word: String
    let conjugated: String
    let type: String?
}
