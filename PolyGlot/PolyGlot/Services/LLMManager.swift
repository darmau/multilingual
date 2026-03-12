import Foundation
import Observation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum LLMError: LocalizedError {
    case missingAPIKey
    case offline
    case noLLMAvailable
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parsingError
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API Key 未设置，请在「设置」中填写对应的 API Key 以使用云端 AI 功能。"
        case .offline:
            return "网络不可用，请检查您的网络连接。"
        case .noLLMAvailable:
            return "当前无可用的 AI 服务。请配置 API Key 或使用支持 Apple Intelligence 的设备。"
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

    /// Returns true when the error is actionable by going to Settings.
    var requiresSettingsNavigation: Bool {
        if case .missingAPIKey = self { return true }
        if case .noLLMAvailable = self { return true }
        return false
    }
}

@Observable
final class LLMManager {
    private(set) var isLoading = false

    /// Attempts to send a prompt, preferring Apple Intelligence when available,
    /// then falling back to the cloud LLM with the configured API key.
    func sendPrompt(_ prompt: String, systemPrompt: String, settings: Settings) async throws -> String {
        // Try Apple Intelligence first if available (on-device, no network needed)
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            if await AppleIntelligenceAvailability.isAvailable {
                let service = AppleIntelligenceService()
                isLoading = true
                defer { isLoading = false }
                do {
                    return try await service.sendPrompt(prompt, systemPrompt: systemPrompt)
                } catch {
                    // Apple Intelligence failed — fall through to cloud provider
                }
            }
        }
        #endif

        // Cloud provider requires network
        guard NetworkMonitor.shared.isConnected else {
            throw LLMError.offline
        }

        // Cloud provider requires API key
        guard settings.hasActiveAPIKey else {
            throw LLMError.missingAPIKey
        }

        let service = createCloudService(for: settings)
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

    /// Returns true when at least one LLM backend is usable (Apple Intelligence or configured API key).
    @MainActor
    static func hasAvailableLLM(settings: Settings) -> Bool {
        if AppleIntelligenceAvailability.isAvailable {
            return true
        }
        return settings.hasActiveAPIKey
    }

    func testConnection(settings: Settings) async throws -> String {
        try await sendPrompt("Hello", systemPrompt: "Reply in one short sentence.", settings: settings)
    }

    private func createCloudService(for settings: Settings) -> LLMServiceProtocol {
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
