import Foundation

protocol TTSServiceProtocol {
    func speak(text: String, language: SupportedLanguage) async throws
}
