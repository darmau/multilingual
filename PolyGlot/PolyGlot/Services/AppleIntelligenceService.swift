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
}
#endif

/// Utility to detect Apple Intelligence availability at runtime.
enum AppleIntelligenceAvailability {

    /// Returns true when the current device/OS supports on-device Foundation Models.
    @MainActor
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return _checkAvailability()
        }
        #endif
        return false
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private static func _checkAvailability() -> Bool {
        return SystemLanguageModel.default.isAvailable
    }
    #endif
}
