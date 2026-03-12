import Foundation

protocol LLMServiceProtocol {
    func sendPrompt(_ prompt: String, systemPrompt: String) async throws -> String

    /// Streams the response token-by-token via Server-Sent Events.
    /// Yields incremental text chunks; the caller accumulates them as needed.
    func streamPrompt(_ prompt: String, systemPrompt: String) -> AsyncThrowingStream<String, Error>
}
