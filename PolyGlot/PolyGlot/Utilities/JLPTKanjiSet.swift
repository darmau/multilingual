import Foundation

/// Loads and caches the JLPT kanji data, providing proficiency-based filtering.
///
/// Usage:
///   let set = JLPTKanjiSet.shared
///   set.needsFurigana(kanji: "食", proficiency: .n4)  // true — 食 is N5, above N4
final class JLPTKanjiSet {
    static let shared = JLPTKanjiSet()

    /// Kanji sets keyed by level. Only N5 and N4 are loaded for now.
    private let n5: Set<Character>
    private let n4: Set<Character>

    private init() {
        guard
            let url = Bundle.main.url(forResource: "jlpt_kanji", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let json = try? JSONDecoder().decode([String: [String]].self, from: data)
        else {
            n5 = []
            n4 = []
            return
        }

        n5 = Set((json["n5"] ?? []).compactMap { $0.first })
        n4 = Set((json["n4"] ?? []).compactMap { $0.first })
    }

    /// Returns the JLPT level of a single kanji character, or `nil` if unknown.
    func level(of kanji: Character) -> JapaneseProficiency? {
        if n5.contains(kanji) { return .n5 }
        if n4.contains(kanji) { return .n4 }
        return nil
    }

    /// Determines whether a kanji string needs furigana annotation given the
    /// user's proficiency level.
    ///
    /// Rules:
    /// - `.beginner`: always annotate all kanji
    /// - `.n5`: annotate everything EXCEPT N5 kanji (user already knows them)
    /// - `.n4`: annotate everything EXCEPT N5+N4 kanji
    /// - `.n3 / .n2 / .n1`: annotate only unknown kanji (no data yet → always show)
    /// - `.native`: never annotate
    func needsFurigana(kanji: String, proficiency: JapaneseProficiency) -> Bool {
        switch proficiency {
        case .native:
            return false
        case .beginner:
            return true
        case .n5:
            // Know N5 — hide N5 furigana
            return !kanji.unicodeScalars.allSatisfy { n5.contains(Character($0)) }
        case .n4:
            // Know N5+N4 — hide furigana for those
            return !kanji.unicodeScalars.allSatisfy {
                let c = Character($0)
                return n5.contains(c) || n4.contains(c)
            }
        case .n3, .n2, .n1:
            // No higher-level data yet — show all furigana as fallback
            return true
        }
    }
}
