import Foundation
import NaturalLanguage

enum LanguageDetector {
    /// Detects the dominant language of the input text.
    /// Returns a `SupportedLanguage` if the detected language is one we support, otherwise `nil`.
    static func detect(_ text: String) -> SupportedLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        guard let dominant = recognizer.dominantLanguage else {
            return nil
        }

        return mapToSupported(dominant)
    }

    private static func mapToSupported(_ language: NLLanguage) -> SupportedLanguage? {
        switch language {
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
