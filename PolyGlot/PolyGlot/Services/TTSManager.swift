import Foundation
import Observation

@Observable
@MainActor
final class TTSManager {
    private(set) var isSpeaking = false

    // Long-lived service instances so audio player state is preserved
    private let appleService = AppleLocalTTSService()
    private var openAIService: OpenAITTSService?

    /// Current in-flight TTS task — kept so it can be cancelled.
    private var currentTask: Task<Void, Never>?

    func speak(text: String, language: SupportedLanguage, settings: Settings) {
        // 中文不需要朗读
        guard language != .chinese else { return }

        // Cancel and stop any ongoing speech before starting a new one
        currentTask?.cancel()

        currentTask = Task {
            await _speak(text: text, language: language, settings: settings)
        }
    }

    private func _speak(text: String, language: SupportedLanguage, settings: Settings) async {
        isSpeaking = true
        defer { isSpeaking = false }

        let service: any TTSServiceProtocol
        if settings.selectedTTSProvider == .openaiTTS {
            // Reuse same instance so AVAudioPlayer reference lives on
            if openAIService == nil || openAIService?.apiKey != settings.openaiAPIKey {
                openAIService = OpenAITTSService(apiKey: settings.openaiAPIKey)
            }
            service = openAIService!
        } else {
            service = appleService
        }

        do {
            try await service.speak(text: text, language: language)
        } catch is CancellationError {
            // Silently ignore
        } catch {
            // Errors are surfaced via SpeakButton's own error handling
        }
    }

    /// Stops any current speech immediately.
    func stop() {
        currentTask?.cancel()
        isSpeaking = false
    }
}
