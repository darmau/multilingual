import Foundation
import AVFoundation

final class AppleLocalTTSService: TTSServiceProtocol {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(text: String, language: SupportedLanguage) async throws {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: voiceIdentifier(for: language))
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        await MainActor.run {
            synthesizer.stopSpeaking(at: .immediate)
            synthesizer.speak(utterance)
        }
    }

    private func voiceIdentifier(for language: SupportedLanguage) -> String {
        switch language {
        case .english: return "en-US"
        case .japanese: return "ja-JP"
        case .korean: return "ko-KR"
        case .chinese: return "zh-CN"
        }
    }
}
