import Foundation

final class GeminiService: LLMServiceProtocol {
    private let apiKey: String
    private let model: String

    init(apiKey: String, model: String = "gemini-2.5-flash") {
        self.apiKey = apiKey
        self.model = model
    }

    func sendPrompt(_ prompt: String, systemPrompt: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw LLMError.missingAPIKey
        }

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw LLMError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "systemInstruction": [
                "parts": [
                    ["text": systemPrompt]
                ]
            ]
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

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let contentObj = firstCandidate["content"] as? [String: Any],
              let parts = contentObj["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw LLMError.parsingError
        }

        return text
    }

    func streamPrompt(_ prompt: String, systemPrompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard !self.apiKey.isEmpty else {
                        continuation.finish(throwing: LLMError.missingAPIKey)
                        return
                    }

                    // Gemini streaming uses streamGenerateContent endpoint
                    let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(self.model):streamGenerateContent?key=\(self.apiKey)&alt=sse"
                    guard let url = URL(string: urlString) else {
                        continuation.finish(throwing: LLMError.invalidURL)
                        return
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

                    let body: [String: Any] = [
                        "contents": [
                            [
                                "parts": [
                                    ["text": prompt]
                                ]
                            ]
                        ],
                        "systemInstruction": [
                            "parts": [
                                ["text": systemPrompt]
                            ]
                        ]
                    ]

                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: LLMError.invalidResponse)
                        return
                    }

                    guard (200...299).contains(httpResponse.statusCode) else {
                        continuation.finish(throwing: LLMError.apiError(statusCode: httpResponse.statusCode, message: "Stream request failed"))
                        return
                    }

                    // Gemini SSE format: data: {"candidates":[{"content":{"parts":[{"text":"..."}]}}]}
                    for try await line in asyncBytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonPart = String(line.dropFirst(6))

                        guard let data = jsonPart.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let candidates = json["candidates"] as? [[String: Any]],
                              let firstCandidate = candidates.first,
                              let contentObj = firstCandidate["content"] as? [String: Any],
                              let parts = contentObj["parts"] as? [[String: Any]],
                              let firstPart = parts.first,
                              let text = firstPart["text"] as? String else {
                            continue
                        }

                        continuation.yield(text)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
