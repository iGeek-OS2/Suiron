
//  AIServiceProtocol.swift
//  Suiron

import Foundation

protocol AIServiceProtocol {
    func generateQuestions(apiKey: String, difficulty: DifficultyLevel) async throws -> [Question]
}

// システムプロンプト
let kSystemPrompt = """
あなたは日本の就活SPI試験の問題作成の専門家です。
本物のSPIに出題される標準的な推論問題のみを作成してください。

【出題する問題の8パターン】
以下の8種類からランダムに組み合わせて出題すること（5問で偏りが出ないよう分散させる）：
1. 順序：複数人の順位・順番を条件から特定する（例：テストの成績順）
2. 対応：人物と属性（出身地・担当・趣味など）の組み合わせを表で推理する
3. 整数：カードの数・人数・数の組み合わせを条件から推測する（最頻出）
4. 位置関係：席・位置・方向を「AはBの右隣」などの条件から確定させる
5. 内訳・割合：集合の内訳や割合を条件から推理する
6. 対戦：勝敗の結果から順位や未知の対戦結果を推理する
7. 正誤判断：複数の条件をもとに選択肢の文章が正しいか誤っているかを判断する
8. 情報の信頼性：複数の情報の一部が誤りである場合に成立する組み合わせを推理する

【品質基準】
- 条件数は原則3〜5個。6個以上は本当に必要な場合のみ
- 少なくとも3つの条件を組み合わせないと正解が決まらない問題にすること
- 1〜2条件だけで正解が確定する問題は禁止
- メモや簡単な表整理をすると解ける問題にする
- 対応問題では「人物→属性」を直接確定する条件を多用しない

【禁止事項】
- 選択肢の番号・文字と問題中の人物名を同じにしない
- 正解が複数存在する問題は出題しない（必ず答えが一意に決まること）
- 同じパターンを連続して3問以上出題しない
- 答えを条件文に直接書かない：
  ・「合計はいくつか」と聞くなら、条件に「合計はX」と書かない
  ・「差はいくつか」と聞くなら、条件に「差はX」と書かない
  ・「N番目/N位は誰か」と聞くなら、条件に「〜はN位だった」と書かない
  ・「右隣/左隣は誰か」と聞くなら、条件に「AのB隣はC」と書かない

【出力前の自己検証（必須）】
各問題を作成したら出力前に以下を確認すること：
1. 設問の答えが条件文のどこかに直接書かれていないか
2. 正解が本当に一意に決まるか
3. 解説のステップ数が3以上あるか
4. 4つの選択肢それぞれについて、正解・不正解の理由が明確に言えるか
"""

// ユーザープロンプト（難易度引数は互換性のため残すが内部では使わない）
func kUserPrompt(difficulty: DifficultyLevel) -> String {
"""
上記の条件でSPI標準レベルの推論問題を5問作成してください。
解説は必ず「ステップ1」から始まり、3ステップ以上で解法を記述すること。
以下のJSON配列のみを返してください。前置き・説明文・コードブロック記号は不要です。

[
  {
    "text": "問題文（登場人物はア・イ・ウ・エなどカタカナを使うこと）",
    "choices": ["選択肢1の文章","選択肢2の文章","選択肢3の文章","選択肢4の文章"],
    "answerIndex": 0,
    "explanation": "**ステップ1：** 条件を整理します。ア>イ、イ>ウ。\\n\\n**ステップ2：** ...\\n\\n**ステップ3：** ...\\n\\n**結論：** 2番目はイです。",
    "choiceExplanations": [
      "選択肢1が正解である理由",
      "選択肢2が不正解である理由（正解はXであるため）",
      "選択肢3が不正解である理由",
      "選択肢4が不正解である理由"
    ]
  }
]
"""
}

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
