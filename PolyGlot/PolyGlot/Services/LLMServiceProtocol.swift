import Foundation

protocol LLMServiceProtocol {
    func sendPrompt(_ prompt: String, systemPrompt: String) async throws -> String
}
