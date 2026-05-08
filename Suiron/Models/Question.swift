
//  Question.swift
//  Suiron

import Foundation

struct Question: Identifiable, Codable {
    let id: UUID
    let text: String                    // 問題文
    let choices: [String]               // 選択肢（4択）
    let answerIndex: Int                // 正解のindex（0始まり）
    let explanation: String             // 解き方の流れ（全体解説）
    let choiceExplanations: [String]    // 各選択肢の正誤理由（choices と同じ順）

    init(id: UUID = UUID(), text: String, choices: [String], answerIndex: Int, explanation: String, choiceExplanations: [String]) {
        self.id = id
        self.text = text
        self.choices = choices
        self.answerIndex = answerIndex
        self.explanation = explanation
        self.choiceExplanations = choiceExplanations
    }
}
