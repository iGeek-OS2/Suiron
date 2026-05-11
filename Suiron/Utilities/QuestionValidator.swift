
//  QuestionValidator.swift
//  Suiron

import Foundation

// MARK: - ValidationResult

struct ValidationResult {
    let isValid: Bool
    let reasons: [String]

    static let valid = ValidationResult(isValid: true, reasons: [])
    static func invalid(_ reasons: [String]) -> ValidationResult {
        ValidationResult(isValid: false, reasons: reasons)
    }
}

// MARK: - QuestionValidator

struct QuestionValidator {

    func validate(_ question: Question, difficulty: DifficultyLevel = .normal) -> ValidationResult {
        var reasons: [String] = []

        // 1. 選択肢が4つ
        if question.choices.count != 4 {
            reasons.append("選択肢が\(question.choices.count)つ（4つ必要）")
        }

        // 2. answerIndex が 0...3 の範囲内
        if !(0...3).contains(question.answerIndex) {
            reasons.append("answerIndex が範囲外: \(question.answerIndex)")
        }

        // 3. choiceExplanations が4つ
        if question.choiceExplanations.count != 4 {
            reasons.append("choiceExplanations が\(question.choiceExplanations.count)つ（4つ必要）")
        }

        // 4. 問題文・解説・全選択肢が空でない
        if question.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            reasons.append("問題文が空")
        }
        if question.explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            reasons.append("解説が空")
        }
        for (i, choice) in question.choices.enumerated() {
            if choice.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                reasons.append("選択肢\(i + 1)が空")
            }
        }

        // 5. 選択肢が重複していない
        if Set(question.choices).count != question.choices.count {
            reasons.append("選択肢に重複がある")
        }

        // 6. 答えが条件文に直接書かれているパターンを検出
        if let leakReason = detectAnswerLeak(in: question.text) {
            reasons.append(leakReason)
        }

        // 7. ステップ数が3未満（難易度によらず標準3ステップ以上を要求）
        if let stepReason = checkStepCount(question.explanation) {
            reasons.append(stepReason)
        }

        // 8. 条件数が多すぎる（7個以上は質の低い可能性が高い）
        if let condReason = checkConditionCount(in: question.text) {
            reasons.append(condReason)
        }

        return reasons.isEmpty ? .valid : .invalid(reasons)
    }

    // MARK: - 答え直書き検出

    private func detectAnswerLeak(in text: String) -> String? {

        // 合計・和 を聞いているのに、条件に数値が直接書かれている
        // 例：「合計はいくつか」＋「合計は5」
        if (text.contains("合計はいくつ") || text.contains("和はいくつ")) {
            if text.range(of: "(合計|和)[はが][0-9０-９]+", options: .regularExpression) != nil {
                return "答え直書き: 合計・和を聞いているのに条件に数値が直接書かれている"
            }
        }

        // 差 を聞いているのに、条件に数値が直接書かれている
        if text.contains("差はいくつ") {
            if text.range(of: "差[はが][0-9０-９]+", options: .regularExpression) != nil {
                return "答え直書き: 差を聞いているのに条件に数値が直接書かれている"
            }
        }

        // 積 を聞いているのに、条件に数値が直接書かれている
        if text.contains("積はいくつ") {
            if text.range(of: "積[はが][0-9０-９]+", options: .regularExpression) != nil {
                return "答え直書き: 積を聞いているのに条件に数値が直接書かれている"
            }
        }

        // 順位 を聞いているのに、同じ順位が条件に書かれている
        // 例：「2番目に速いのは誰か」＋「オは2位だった」
        if let askedRank = extractAskedRank(from: text) {
            let p1 = "[ァ-ン][はがも]\(askedRank)(位|番目)"  // 「オは2位」
            let p2 = "\(askedRank)(位|番目)[はがでも][ァ-ン]" // 「2位はオ」
            if text.range(of: p1, options: .regularExpression) != nil ||
               text.range(of: p2, options: .regularExpression) != nil {
                return "答え直書き: \(askedRank)位/番目を聞いているのに条件に直接書かれている"
            }
        }

        // 隣関係 を聞いているのに、条件に具体的な隣関係が書かれている
        // 例：「右隣は誰か」＋「アの右隣はイ」
        for neighbor in ["右隣", "左隣", "正面"] {
            if text.contains("\(neighbor)は誰") || text.contains("\(neighbor)の人") {
                if text.range(of: "[ァ-ン]の\(neighbor)は[ァ-ン]", options: .regularExpression) != nil {
                    return "答え直書き: \(neighbor)を聞いているのに条件に隣関係が直接書かれている"
                }
            }
        }

        return nil
    }

    /// 設問から「N番目」「N位」として聞いている順位の数字を返す
    private func extractAskedRank(from text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: "([1-9１-９])([番位])目?[にはがのでも]") else { return nil }
        let nsRange = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: nsRange),
              let rankRange = Range(match.range(at: 1), in: text) else { return nil }
        let rank = String(text[rankRange])
        // 全角数字を半角に変換
        return rank.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? rank
    }

    // MARK: - ステップ数チェック（難易度によらず3以上を要求）

    private func checkStepCount(_ explanation: String) -> String? {
        let count = countSteps(in: explanation)
        guard count >= 3 else {
            return "ステップ数が\(count)（3以上必要）"
        }
        return nil
    }

    /// explanation 中の「ステップN」「Step N」の出現回数を返す
    private func countSteps(in text: String) -> Int {
        let patterns = ["ステップ\\s*[0-9１-９]", "Step\\s*[0-9]"]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0, options: .caseInsensitive) }
            .reduce(0) { total, regex in
                total + regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
            }
    }

    // MARK: - 条件数チェック（7個以上は質が低い可能性）

    private func checkConditionCount(in text: String) -> String? {
        let count = countConditions(in: text)
        guard count >= 7 else { return nil }
        return "条件数が\(count)個（6個以下が望ましい）"
    }

    /// 問題文中の箇条書き条件（・①②③など）の数を返す
    private func countConditions(in text: String) -> Int {
        guard let regex = try? NSRegularExpression(
            pattern: "^[・•]|^[①②③④⑤⑥⑦⑧⑨]|^条件[0-9]",
            options: .anchorsMatchLines
        ) else { return 0 }
        return regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
    }
}
