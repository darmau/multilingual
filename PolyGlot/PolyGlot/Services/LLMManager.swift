import Foundation
import Observation

enum LLMError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parsingError
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API Key 未设置，请在设置中填写对应的 API Key。"
        case .invalidURL:
            return "请求 URL 无效。"
        case .invalidResponse:
            return "服务器返回了无效的响应。"
        case .apiError(let statusCode, let message):
            return "API 错误 (\(statusCode)): \(message)"
        case .parsingError:
            return "无法解析服务器响应。"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        }
    }
}

@Observable
final class LLMManager {
    private(set) var isLoading = false

    func sendPrompt(_ prompt: String, systemPrompt: String, settings: Settings) async throws -> String {
        let service = createService(for: settings)
        isLoading = true
        defer { isLoading = false }

        do {
            return try await service.sendPrompt(prompt, systemPrompt: systemPrompt)
        } catch let error as LLMError {
            throw error
        } catch let error as URLError {
            throw LLMError.networkError(error)
        } catch {
            throw LLMError.networkError(error)
        }
    }

    func testConnection(settings: Settings) async throws -> String {
        try await sendPrompt("Hello", systemPrompt: "Reply in one short sentence.", settings: settings)
    }

    private func createService(for settings: Settings) -> LLMServiceProtocol {
        switch settings.selectedLLMProvider {
        case .openai:
            return OpenAIService(apiKey: settings.openaiAPIKey)
        case .claude:
            return ClaudeService(apiKey: settings.claudeAPIKey)
        case .gemini:
            return GeminiService(apiKey: settings.geminiAPIKey)
        }
    }
}
