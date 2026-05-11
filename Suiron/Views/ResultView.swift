
//  ResultView.swift
//  Suiron

import SwiftUI

// MARK: - ResultView

struct ResultView: View {
    let questions: [Question]
    let userAnswers: [Int]
    let onPlayAgain: () -> Void

    @State private var displayedScore = 0
    @State private var showItems = false

    private var score: Int {
        zip(questions, userAnswers)
            .filter { question, answer in question.answerIndex == answer }
            .count
    }

    private var comment: String {
        switch score {
        case 5: return "完璧です！SPI余裕ですね"
        case 4: return "あと一歩！惜しかった"
        case 3: return "半分クリア。もう一度挑戦を"
        default: return "推論問題、一緒に鍛えましょう"
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // スコア（カウントアップ）
                VStack(spacing: 8) {
                    Text("\(displayedScore) / \(questions.count)")
                        .font(.system(size: 64, design: .serif).weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                        .contentTransition(.numericText())
                    Text(comment)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.textSecondary)
                }



                Spacer()

                // もう一度ボタン
                Button("もう一度", action: onPlayAgain)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.appBackground)
                    .frame(width: 280, height: 52)
                    .background(Color.accent)
                    .clipShape(Capsule())
                    .opacity(showItems ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.8), value: showItems)

                Spacer().frame(height: 80)
            }
        }
        .task {
            if score > 0 {
                for i in 1...score {
                    try? await Task.sleep(for: .milliseconds(150))
                    withAnimation(.easeOut) { displayedScore = i }
                }
            }
            showItems = true
        }
    }
}

// MARK: - Preview

#Preview("結果画面") {
    ResultView(
        questions: MockAIService.sampleQuestions,
        userAnswers: [0, 0, 2, 1, 3],
        onPlayAgain: {}
    )
}
