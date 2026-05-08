
//  ExplanationView.swift
//  Suiron

import SwiftUI

struct ExplanationView: View {
    let question: Question
    let selectedIndex: Int
    let isLast: Bool
    let onNext: () -> Void

    private var isCorrect: Bool { selectedIndex == question.answerIndex }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                // 正誤バッジ
                HStack(spacing: 8) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(isCorrect ? Color.correct : Color.incorrect)
                    Text(isCorrect ? "正解" : "不正解")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isCorrect ? Color.correct : Color.incorrect)
                }
                .padding(.top, 20)

                // 問題文
                sectionCard {
                    Text(question.text)
                        .font(.system(size: 15))
                        .lineSpacing(5)
                        .foregroundStyle(Color.textPrimary)
                }

                // 正解
                sectionCard {
                    VStack(alignment: .leading, spacing: 4) {
                        label("正解")
                        Text(question.choices[question.answerIndex])
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.accent)
                    }
                }

                // 解き方の流れ
                sectionCard {
                    VStack(alignment: .leading, spacing: 8) {
                        label("解き方の流れ")
                        Text(question.explanation)
                            .font(.system(size: 14))
                            .lineSpacing(5)
                            .foregroundStyle(Color.textPrimary)
                    }
                }

                // 各選択肢の解説
                sectionCard {
                    VStack(alignment: .leading, spacing: 14) {
                        label("各選択肢の解説")
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(question.choices.enumerated()), id: \.offset) { i, choice in
                                choiceRow(index: i, choice: choice)
                            }
                        }
                    }
                }

                // 次へボタン
                Button(isLast ? "結果を見る" : "次の問題へ", action: onNext)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.top, 4)

                Spacer().frame(height: 32)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Helpers

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.textSecondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    @ViewBuilder
    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func choiceRow(index: Int, choice: String) -> some View {
        let correct = index == question.answerIndex
        let explanation = index < question.choiceExplanations.count
            ? question.choiceExplanations[index] : ""
        return VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: correct ? "checkmark" : "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(correct ? Color.accent : Color.textSecondary)
                    .frame(width: 16, height: 16)
                    .padding(.top, 1)
                Text(choice)
                    .font(.system(size: 14, weight: correct ? .semibold : .regular))
                    .foregroundStyle(correct ? Color.accent : Color.textPrimary)
            }
            Text(explanation)
                .font(.system(size: 12))
                .lineSpacing(3)
                .foregroundStyle(Color.textSecondary)
                .padding(.leading, 24)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        ExplanationView(
            question: MockAIService.sampleQuestions[0],
            selectedIndex: 2,
            isLast: false,
            onNext: {}
        )
    }
}
