import Foundation
import Observation

@Observable
final class TTSManager {
    private(set) var isSpeaking = false

    func speak(text: String, language: SupportedLanguage, settings: Settings) async throws {
        // 中文不需要朗读
        guard language != .chinese else { return }

        let service = createService(for: settings)
        isSpeaking = true
        defer { isSpeaking = false }

        do {
            try await service.speak(text: text, language: language)
        } catch let error as TTSError {
            throw error
        } catch let error as URLError {
            throw TTSError.networkError(error)
        } catch {
            throw TTSError.networkError(error)
        }
    }

    private func createService(for settings: Settings) -> TTSServiceProtocol {
        switch settings.selectedTTSProvider {
        case .openaiTTS:
            return OpenAITTSService(apiKey: settings.openaiAPIKey)
        case .appleLocal:
            return AppleLocalTTSService()
        }
    }
}
