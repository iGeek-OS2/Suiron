
//  GeminiService.swift
//  Suiron

import Foundation

struct GeminiService: AIServiceProtocol {
    private let provider = AIProvider.gemini

    func generateQuestions(apiKey: String) async throws -> [Question] {
        // GeminiはAPIキーをクエリパラメータで渡す
        var components = URLComponents(url: provider.endpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        guard let url = components?.url else {
            throw AppError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": kGeneratePrompt]]]
            ]
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
