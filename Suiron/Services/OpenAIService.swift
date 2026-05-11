
//  OpenAIService.swift
//  Suiron

import Foundation

struct OpenAIService: AIServiceProtocol {
    private let provider = AIProvider.openai

    func generateQuestions(apiKey: String, difficulty: DifficultyLevel) async throws -> [Question] {
        var request = URLRequest(url: provider.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": provider.modelID,
            "messages": [
                ["role": "system", "content": kSystemPrompt],
                ["role": "user", "content": kUserPrompt(difficulty: difficulty)]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw AppError.invalidResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AppError.invalidResponse
        }

        return try parseQuestions(from: content)
    }
}
