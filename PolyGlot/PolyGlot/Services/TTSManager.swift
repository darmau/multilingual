import Foundation
import Observation

@Observable
@MainActor
final class TTSManager {
    private(set) var isSpeaking = false

    // Keep the Apple TTS service alive for the lifetime of the manager so
    // the synthesizer is not recreated on every speak call.
    private let appleService = AppleLocalTTSService()

    func speak(text: String, language: SupportedLanguage, settings: Settings) async throws {
        // 中文不需要朗读
        guard language != .chinese else { return }

        isSpeaking = true
        defer { isSpeaking = false }

        let service: any TTSServiceProtocol = settings.selectedTTSProvider == .openaiTTS
            ? OpenAITTSService(apiKey: settings.openaiAPIKey)
            : appleService

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
}
