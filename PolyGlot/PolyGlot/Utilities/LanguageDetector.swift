import Foundation
import NaturalLanguage

enum LanguageDetector {
    static func detect(_ text: String) -> SupportedLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        guard let dominant = recognizer.dominantLanguage else {
            return nil
        }

        switch dominant {
        case .simplifiedChinese, .traditionalChinese:
            return .chinese
        case .english:
            return .english
        case .japanese:
            return .japanese
        case .korean:
            return .korean
        default:
            return nil
        }
    }
}
