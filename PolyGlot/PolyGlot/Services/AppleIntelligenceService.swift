import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// LLM service that uses on-device Apple Intelligence via the Foundation Models framework.
/// Available on iOS 26.0+ / macOS 26.0+ devices that support Apple Intelligence.
#if canImport(FoundationModels)
@available(iOS 26.0, macOS 26.0, *)
final class AppleIntelligenceService: LLMServiceProtocol {

    func sendPrompt(_ prompt: String, systemPrompt: String) async throws -> String {
        let session = LanguageModelSession(instructions: systemPrompt)
        let response = try await session.respond(to: prompt)
        return response.content
    }

    func streamPrompt(_ prompt: String, systemPrompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let session = LanguageModelSession(instructions: systemPrompt)
                    let stream = session.streamResponse(to: prompt)
                    var lastText = ""
                    for try await partial in stream {
                        // Foundation Models streams the full text so far; yield only the delta
                        let delta = String(partial.content.dropFirst(lastText.count))
                        if !delta.isEmpty {
                            continuation.yield(delta)
                        }
                        lastText = partial.content
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
#endif

/// Utility to detect Apple Intelligence availability at runtime.
enum AppleIntelligenceAvailability {

    /// Returns true when the on-device Foundation Models are ready to use.
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return SystemLanguageModel.default.availability == .available
        }
        #endif
        return false
    }

    /// Returns a human-readable description of the availability status for diagnostics.
    static var statusDescription: String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return "Available"
            case .unavailable(let reason):
                switch reason {
                case .deviceNotEligible:
                    return "Unavailable: device not eligible"
                case .appleIntelligenceNotEnabled:
                    return "Unavailable: Apple Intelligence not enabled in System Settings"
                case .modelNotReady:
                    return "Unavailable: model not ready (still downloading)"
                default:
                    return "Unavailable: \(reason)"
                }
            @unknown default:
                return "Unknown state"
            }
        }
        #endif
        return "Unavailable: OS < 26.0"
    }
}
