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
            return String(localized: "API Key not set. Please enter your API Key in Settings to use cloud AI.")
        case .offline:
            return String(localized: "Network unavailable. Please check your connection.")
        case .noLLMAvailable:
            return String(localized: "No AI service available. Please configure an API Key or use a device with Apple Intelligence.")
        case .invalidURL:
            return String(localized: "Invalid request URL.")
        case .invalidResponse:
            return String(localized: "Server returned an invalid response.")
        case .apiError(let statusCode, let message):
            return String(localized: "API error (\(statusCode)): \(message)")
        case .parsingError:
            return String(localized: "Unable to parse server response.")
        case .networkError(let error):
            return String(localized: "Network error: \(error.localizedDescription)")
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
    /// then falling back to the cloud LLM. Pass `overrideProvider` to use a specific
    /// cloud provider instead of `settings.selectedLLMProvider`.
    func sendPrompt(
        _ prompt: String,
        systemPrompt: String,
        settings: Settings,
        overrideProvider: LLMProvider? = nil
    ) async throws -> String {
        // Try Apple Intelligence first if available (on-device, no network needed)
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            if AppleIntelligenceAvailability.isAvailable {
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

        let provider = overrideProvider ?? settings.selectedLLMProvider
        guard !apiKey(for: provider, settings: settings).isEmpty else {
            throw LLMError.missingAPIKey
        }

        let service = createCloudService(for: provider, settings: settings)
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
    static func hasAvailableLLM(settings: Settings) -> Bool {
        if AppleIntelligenceAvailability.isAvailable {
            return true
        }
        return settings.hasActiveAPIKey
    }

    /// Streams the response token-by-token. Falls back to non-streaming if Apple Intelligence
    /// is available (wraps single response as a single-chunk stream). Pass `overrideProvider`
    /// to use a specific cloud provider instead of `settings.selectedLLMProvider`.
    func streamPrompt(
        _ prompt: String,
        systemPrompt: String,
        settings: Settings,
        overrideProvider: LLMProvider? = nil
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                // Try Apple Intelligence first (supports native streaming)
                #if canImport(FoundationModels)
                if #available(iOS 26.0, macOS 26.0, *) {
                    if AppleIntelligenceAvailability.isAvailable {
                        let service = AppleIntelligenceService()
                        self.isLoading = true
                        do {
                            for try await chunk in service.streamPrompt(prompt, systemPrompt: systemPrompt) {
                                continuation.yield(chunk)
                            }
                            self.isLoading = false
                            continuation.finish()
                            return
                        } catch {
                            self.isLoading = false
                            // Fall through to cloud provider
                        }
                    }
                }
                #endif

                // Cloud provider requires network
                guard NetworkMonitor.shared.isConnected else {
                    continuation.finish(throwing: LLMError.offline)
                    return
                }

                let provider = overrideProvider ?? settings.selectedLLMProvider
                guard !self.apiKey(for: provider, settings: settings).isEmpty else {
                    continuation.finish(throwing: LLMError.missingAPIKey)
                    return
                }

                let service = self.createCloudService(for: provider, settings: settings)
                self.isLoading = true
                do {
                    for try await chunk in service.streamPrompt(prompt, systemPrompt: systemPrompt) {
                        continuation.yield(chunk)
                    }
                    self.isLoading = false
                    continuation.finish()
                } catch let error as LLMError {
                    self.isLoading = false
                    continuation.finish(throwing: error)
                } catch let error as URLError {
                    self.isLoading = false
                    continuation.finish(throwing: LLMError.networkError(error))
                } catch {
                    self.isLoading = false
                    continuation.finish(throwing: LLMError.networkError(error))
                }
            }
        }
    }

    func testConnection(settings: Settings) async throws -> String {
        try await sendPrompt("Hello", systemPrompt: "Reply in one short sentence.", settings: settings)
    }

    private func apiKey(for provider: LLMProvider, settings: Settings) -> String {
        switch provider {
        case .openai: return settings.openaiAPIKey
        case .claude: return settings.claudeAPIKey
        case .gemini: return settings.geminiAPIKey
        }
    }

    private func createCloudService(for provider: LLMProvider, settings: Settings) -> LLMServiceProtocol {
        switch provider {
        case .openai:
            return OpenAIService(apiKey: settings.openaiAPIKey)
        case .claude:
            return ClaudeService(apiKey: settings.claudeAPIKey)
        case .gemini:
            return GeminiService(apiKey: settings.geminiAPIKey)
        }
    }
}
