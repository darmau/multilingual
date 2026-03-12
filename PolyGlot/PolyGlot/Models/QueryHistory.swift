import Foundation
import SwiftData

/// Persists recent user queries for Dictionary and Sentence modes.
@Model
final class QueryHistory {
    var text: String
    var languageRaw: String
    var modeRaw: String
    var createdAt: Date

    var language: SupportedLanguage {
        get { SupportedLanguage(rawValue: languageRaw) ?? .english }
        set { languageRaw = newValue.rawValue }
    }

    var mode: QueryMode {
        get { QueryMode(rawValue: modeRaw) ?? .dictionary }
        set { modeRaw = newValue.rawValue }
    }

    init(text: String, language: SupportedLanguage, mode: QueryMode) {
        self.text = text
        self.languageRaw = language.rawValue
        self.modeRaw = mode.rawValue
        self.createdAt = Date()
    }

    enum QueryMode: String {
        case dictionary
        case sentence
    }
}
