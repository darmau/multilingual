import Foundation
import AVFoundation

@MainActor
final class AppleLocalTTSService: TTSServiceProtocol {
    // Synthesizer must live on the main actor to avoid the voice-fetching
    // decoding warning introduced in iOS 18 / macOS 15.
    private let synthesizer = AVSpeechSynthesizer()

    func speak(text: String, language: SupportedLanguage) async throws {
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        // Use a pre-fetched voice object rather than letting the system look
        // one up lazily, which triggers the internal decoding warning.
        utterance.voice = bestVoice(for: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        synthesizer.speak(utterance)
    }

    private func bestVoice(for language: SupportedLanguage) -> AVSpeechSynthesisVoice? {
        let code = language.languageCode
        // Prefer an enhanced/premium voice when available; fall back to any
        // voice that matches the language code.
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let enhanced = voices.first {
            $0.language.hasPrefix(code) &&
            ($0.quality == .enhanced || $0.quality == .premium)
        }
        return enhanced ?? AVSpeechSynthesisVoice(language: code)
    }
}
