
//  AIServiceProtocol.swift
//  Suiron

import Foundation

protocol AIServiceProtocol {
    func generateQuestions(apiKey: String) async throws -> [Question]
}

// AI共通プロンプト
let kGeneratePrompt = """
就活SPIの推論問題（発言の真偽を推理するタイプ）を5問作成してください。
難易度：普通。
以下のJSON配列のみを返してください。説明文は不要です。

[
  {
    "text": "問題文",
    "choices": ["選択肢A","選択肢B","選択肢C","選択肢D"],
    "answerIndex": 0,
    "explanation": "解き方の流れ（全体的な解法の説明）",
    "choiceExplanations": [
      "選択肢Aが正解である理由",
      "選択肢Bが不正解である理由",
      "選択肢Cが不正解である理由",
      "選択肢Dが不正解である理由"
    ]
  }
]
"""

// AIレスポンスからJSON配列を抽出してQuestionにデコードする共通処理
func parseQuestions(from rawText: String) throws -> [Question] {
    // マークダウンコードブロックを除去
    var text = rawText
        .replacingOccurrences(of: "```json", with: "")
        .replacingOccurrences(of: "```", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)

    // JSON配列の範囲を抽出
    guard let start = text.firstIndex(of: "["),
          let end = text.lastIndex(of: "]") else {
        throw AppError.jsonParseError
    }
    text = String(text[start...end])

    guard let data = text.data(using: .utf8) else {
        throw AppError.jsonParseError
    }

    do {
        let decoded = try JSONDecoder().decode([QuestionResponse].self, from: data)
        return decoded.map { $0.toQuestion() }
    } catch {
        throw AppError.jsonParseError
    }
}

// AIレスポンスのデコード用中間モデル（idなし）
private struct QuestionResponse: Decodable {
    let text: String
    let choices: [String]
    let answerIndex: Int
    let explanation: String
    let choiceExplanations: [String]

    func toQuestion() -> Question {
        Question(text: text, choices: choices, answerIndex: answerIndex, explanation: explanation, choiceExplanations: choiceExplanations)
    }
}
