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

// MARK: - Language Analyses Container (dynamic keys)

struct LanguageAnalyses: Codable {
    /// Dictionary keyed by SupportedLanguage.rawValue (e.g., "english", "japanese").
    let entries: [String: GenericWordAnalysis]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode([String: GenericWordAnalysis].self)
        entries = raw
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(entries)
    }

    /// Convenience accessor by SupportedLanguage.
    func analysis(for language: SupportedLanguage) -> GenericWordAnalysis? {
        entries[language.rawValue]
    }

    // MARK: - Legacy accessors for backward compatibility with existing views

    var english: EnglishAnalysis? {
        guard let g = entries["english"] else { return nil }
        return EnglishAnalysis(from: g)
    }

    var chinese: ChineseAnalysis? {
        guard let g = entries["chinese"] else { return nil }
        return ChineseAnalysis(from: g)
    }

    var japanese: JapaneseAnalysis? {
        guard let g = entries["japanese"] else { return nil }
        return JapaneseAnalysis(from: g)
    }

    var korean: KoreanAnalysis? {
        guard let g = entries["korean"] else { return nil }
        return KoreanAnalysis(from: g)
    }
}

// MARK: - Generic Word Analysis (works for any language)

struct GenericWordAnalysis: Codable {
    let word: String?
    let definitions: [GenericDefinition]?
    let phonetic: String?
    let reading: String?
    let pinyin: String?
    let transliteration: String?
    let gender: String?
    let root: String?
    let etymology: String?
    let conjugation: String?
    let synonyms: [String]?
    let antonyms: [String]?
}

struct GenericDefinition: Codable {
    let pos: String?
    let meaning: String
    let example: String?
    let exampleReading: String?

    enum CodingKeys: String, CodingKey {
        case pos, meaning, example
        case exampleReading = "example_reading"
    }
}

// MARK: - Legacy Per-Language Analysis Types (for existing views)

struct EnglishAnalysis: Codable {
    let definitions: [EnglishDefinition]
    let phonetic: String?
    let etymology: String?
    let synonyms: [String]?
    let antonyms: [String]?

    init(from g: GenericWordAnalysis) {
        self.definitions = g.definitions?.map {
            EnglishDefinition(pos: $0.pos ?? "", meaning: $0.meaning, example: $0.example)
        } ?? []
        self.phonetic = g.phonetic
        self.etymology = g.etymology
        self.synonyms = g.synonyms
        self.antonyms = g.antonyms
    }
}

struct EnglishDefinition: Codable {
    let pos: String
    let meaning: String
    let example: String?
}

struct ChineseAnalysis: Codable {
    let word: String
    let definitions: [ChineseDefinition]
    let pinyin: String?

    init(from g: GenericWordAnalysis) {
        self.word = g.word ?? ""
        self.definitions = g.definitions?.map { ChineseDefinition(meaning: $0.meaning) } ?? []
        self.pinyin = g.pinyin
    }
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

    init(from g: GenericWordAnalysis) {
        self.word = g.word ?? ""
        self.reading = g.reading
        self.definitions = g.definitions?.map {
            JapaneseDefinition(pos: $0.pos, meaning: $0.meaning, example: $0.example, exampleReading: $0.exampleReading)
        } ?? []
        self.etymology = g.etymology
        self.conjugation = g.conjugation
        self.synonyms = g.synonyms
        self.antonyms = g.antonyms
    }
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

    init(from g: GenericWordAnalysis) {
        self.word = g.word ?? ""
        self.reading = g.reading
        self.definitions = g.definitions?.map {
            KoreanDefinition(pos: $0.pos, meaning: $0.meaning, example: $0.example)
        } ?? []
        self.etymology = g.etymology
        self.conjugation = g.conjugation
    }
}

struct KoreanDefinition: Codable {
    let pos: String?
    let meaning: String
    let example: String?
}
