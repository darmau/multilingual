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

// MARK: - Analyses Container (dynamic keys)

struct SentenceLanguageAnalyses: Codable {
    /// Dictionary keyed by SupportedLanguage.rawValue.
    let entries: [String: GenericSentenceAnalysis]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode([String: GenericSentenceAnalysis].self)
        entries = raw
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(entries)
    }

    func analysis(for language: SupportedLanguage) -> GenericSentenceAnalysis? {
        entries[language.rawValue]
    }

    // MARK: - Legacy accessors

    var english: EnglishSentenceAnalysis? {
        guard let g = entries["english"] else { return nil }
        return EnglishSentenceAnalysis(from: g)
    }

    var chinese: ChineseSentenceAnalysis? {
        guard let g = entries["chinese"] else { return nil }
        return ChineseSentenceAnalysis(translation: g.translation ?? "")
    }

    var japanese: JapaneseSentenceAnalysis? {
        guard let g = entries["japanese"] else { return nil }
        return JapaneseSentenceAnalysis(from: g)
    }

    var korean: KoreanSentenceAnalysis? {
        guard let g = entries["korean"] else { return nil }
        return KoreanSentenceAnalysis(from: g)
    }
}

// MARK: - Generic Sentence Analysis (works for any language)

struct GenericSentenceAnalysis: Codable {
    let translation: String?
    let translationReading: String?
    let grammar: GenericGrammar?

    enum CodingKeys: String, CodingKey {
        case translation
        case translationReading = "translation_reading"
        case grammar
    }
}

struct GenericGrammar: Codable {
    let structure: String?
    let tense: String?
    let voice: String?
    let mood: String?
    let caseUsage: String?
    let clauses: [String]?
    let particles: [GenericParticle]?
    let conjugations: [Conjugation]?
    let politenessLevel: String?
    let keyPhrases: [GenericKeyPhrase]?
    let keyPatterns: [GenericKeyPattern]?

    enum CodingKeys: String, CodingKey {
        case structure, tense, voice, mood, clauses, particles, conjugations
        case caseUsage = "case_usage"
        case politenessLevel = "politeness_level"
        case keyPhrases = "key_phrases"
        case keyPatterns = "key_patterns"
    }
}

struct GenericParticle: Codable {
    let particle: String
    let function: String
}

struct GenericKeyPhrase: Codable {
    let phrase: String
    let explanation: String
    let grammarPoint: String?

    enum CodingKeys: String, CodingKey {
        case phrase, explanation
        case grammarPoint = "grammar_point"
    }
}

struct GenericKeyPattern: Codable {
    let pattern: String
    let meaning: String
    let usage: String?
}

// MARK: - Legacy Types (for backward compatibility with existing views)

struct ChineseSentenceAnalysis: Codable {
    let translation: String
}

struct EnglishSentenceAnalysis: Codable {
    let translation: String?
    let grammar: EnglishGrammar?

    init(from g: GenericSentenceAnalysis) {
        self.translation = g.translation
        if let gg = g.grammar {
            self.grammar = EnglishGrammar(
                structure: gg.structure,
                tense: gg.tense,
                voice: gg.voice,
                clauses: gg.clauses,
                keyPhrases: gg.keyPhrases?.map {
                    EnglishKeyPhrase(phrase: $0.phrase, explanation: $0.explanation, grammarPoint: $0.grammarPoint)
                }
            )
        } else {
            self.grammar = nil
        }
    }
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

struct JapaneseSentenceAnalysis: Codable {
    let translation: String
    let translationReading: String?
    let grammar: JapaneseGrammar?

    enum CodingKeys: String, CodingKey {
        case translation
        case translationReading = "translation_reading"
        case grammar
    }

    init(from g: GenericSentenceAnalysis) {
        self.translation = g.translation ?? ""
        self.translationReading = g.translationReading
        if let gg = g.grammar {
            self.grammar = JapaneseGrammar(
                structure: gg.structure,
                particles: gg.particles?.map { JapaneseParticle(particle: $0.particle, function: $0.function) },
                conjugations: gg.conjugations,
                politenessLevel: gg.politenessLevel,
                keyPatterns: gg.keyPatterns?.map { JapaneseKeyPattern(pattern: $0.pattern, meaning: $0.meaning, usage: $0.usage) }
            )
        } else {
            self.grammar = nil
        }
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

struct KoreanSentenceAnalysis: Codable {
    let translation: String
    let grammar: KoreanGrammar?

    init(from g: GenericSentenceAnalysis) {
        self.translation = g.translation ?? ""
        if let gg = g.grammar {
            self.grammar = KoreanGrammar(
                structure: gg.structure,
                particles: gg.particles?.map { KoreanParticle(particle: $0.particle, function: $0.function) },
                conjugations: gg.conjugations,
                politenessLevel: gg.politenessLevel,
                keyPatterns: gg.keyPatterns?.map { KoreanKeyPattern(pattern: $0.pattern, meaning: $0.meaning) }
            )
        } else {
            self.grammar = nil
        }
    }
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
