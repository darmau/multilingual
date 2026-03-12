import Foundation

enum TTSError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case playbackError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API Key 未设置，请在设置中填写 OpenAI API Key。"
        case .invalidURL:
            return "TTS 请求 URL 无效。"
        case .invalidResponse:
            return "TTS 服务返回了无效的响应。"
        case .apiError(let statusCode, let message):
            return "TTS API 错误 (\(statusCode)): \(message)"
        case .playbackError(let error):
            return "音频播放失败: \(error.localizedDescription)"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        }
    }
}

@MainActor
protocol TTSServiceProtocol {
    func speak(text: String, language: SupportedLanguage) async throws
}
