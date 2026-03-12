import Foundation

final class OpenAIService: LLMServiceProtocol {
    private let apiKey: String
    private let model: String

    init(apiKey: String, model: String = "gpt-5.4") {
        self.apiKey = apiKey
        self.model = model
    }

    func sendPrompt(_ prompt: String, systemPrompt: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw LLMError.missingAPIKey
        }

        guard let url = URL(string: "https://api.openai.com/v1/responses") else {
            throw LLMError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "instructions": systemPrompt,
            "input": prompt
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LLMError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        // Responses API: output[0].content[0].text
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let output = json["output"] as? [[String: Any]],
              let firstOutput = output.first,
              let content = firstOutput["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw LLMError.parsingError
        }

        return text
    }
}
