import Foundation
import AVFoundation

final class OpenAITTSService: TTSServiceProtocol {
    let apiKey: String
    private var audioPlayer: AVAudioPlayer?

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func speak(text: String, language: SupportedLanguage) async throws {
        guard !apiKey.isEmpty else {
            throw TTSError.missingAPIKey
        }

        guard let url = URL(string: "https://api.openai.com/v1/audio/speech") else {
            throw TTSError.invalidURL
        }

        let voice = voiceForLanguage(language)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "tts-1",
            "input": text,
            "voice": voice
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TTSError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TTSError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        try await playAudioData(data)
    }

    private func voiceForLanguage(_ language: SupportedLanguage) -> String {
        switch language {
        case .english: return "alloy"
        case .japanese: return "nova"
        case .korean: return "shimmer"
        case .chinese: return "alloy"
        case .french: return "nova"
        case .spanish: return "nova"
        case .arabic: return "alloy"
        case .german: return "alloy"
        case .portuguese: return "nova"
        }
    }

    @MainActor
    private func playAudioData(_ data: Data) async throws {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.play()
        } catch {
            throw TTSError.playbackError(error)
        }
    }
}
