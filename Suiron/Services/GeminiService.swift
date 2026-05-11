
//  GeminiService.swift
//  Suiron

import Foundation

struct GeminiService: AIServiceProtocol {

    private func makeURL(model: GeminiModel, operation: String, apiKey: String) -> URL? {
        var components = URLComponents(string: "\(model.baseURL):\(operation)")
        components?.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        return components?.url
    }

    func generateText(prompt: String, apiKey: String) async throws -> String {
        guard let url = makeURL(model: .flash, operation: "generateContent", apiKey: apiKey) else {
            throw AppError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw AppError.invalidResponse
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw AppError.invalidResponse
        }
        return text
    }

    func streamRawText(apiKey: String, difficulty: DifficultyLevel) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = makeURL(model: .flash, operation: "streamGenerateContent", apiKey: apiKey) else {
                        continuation.finish(throwing: AppError.invalidResponse)
                        return
                    }
                    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                    var items = components?.queryItems ?? []
                    items.append(URLQueryItem(name: "alt", value: "sse"))
                    components?.queryItems = items
                    guard let sseURL = components?.url else {
                        continuation.finish(throwing: AppError.invalidResponse)
                        return
                    }

                    var request = URLRequest(url: sseURL)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let body: [String: Any] = [
                        "system_instruction": ["parts": [["text": kSystemPrompt]]],
                        "contents": [["parts": [["text": kUserPrompt(difficulty: difficulty)]]]]
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200..<300).contains(httpResponse.statusCode) else {
                        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                        if code == 429 {
                            continuation.finish(throwing: AppError.rateLimitError)
                        } else {
                            continuation.finish(throwing: AppError.networkError(
                                underlying: NSError(domain: "GeminiAPI", code: code,
                                    userInfo: [NSLocalizedDescriptionKey: "HTTP \(code)"])
                            ))
                        }
                        return
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = String(line.dropFirst(6))
                        guard jsonString != "[DONE]",
                              let data = jsonString.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let candidates = json["candidates"] as? [[String: Any]],
                              let content = candidates.first?["content"] as? [String: Any],
                              let parts = content["parts"] as? [[String: Any]],
                              let text = parts.first?["text"] as? String else { continue }
                        continuation.yield(text)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func generateQuestions(apiKey: String, difficulty: DifficultyLevel) async throws -> [Question] {
        guard let url = makeURL(model: .flash, operation: "generateContent", apiKey: apiKey) else {
            throw AppError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": kSystemPrompt]]],
            "contents": [["parts": [["text": kUserPrompt(difficulty: difficulty)]]]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw AppError.invalidResponse
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw AppError.invalidResponse
        }
        return try parseQuestions(from: text)
    }
}
