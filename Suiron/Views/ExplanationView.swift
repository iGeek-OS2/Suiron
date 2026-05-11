
//  ExplanationView.swift
//  Suiron

import SwiftUI

struct ExplanationView: View {
    let question: Question
    let questionNumber: Int
    let selectedIndex: Int
    let isLast: Bool
    let onNext: () -> Void
    var forPreview: Bool = false

    @State private var explanationExpanded = true
    @State private var assistantText: String? = nil
    @State private var isLoadingAssistant = false
    @State private var assistantBeat = false
    @State private var showAssistantSheet = false

    private var isCorrect: Bool { selectedIndex == question.answerIndex }

    private static let kanjiNumbers = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]

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

                // 問題見出し
                let kanji = questionNumber <= Self.kanjiNumbers.count
                    ? Self.kanjiNumbers[questionNumber - 1] : "\(questionNumber)"
                Text("問題\(kanji)")
                    .font(.system(size: 30, design: .serif).weight(.bold))
                    .foregroundStyle(Color.textPrimary)

                // 問題文 + 正解
                sectionCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(question.text)
                            .font(.system(size: 13, design: .serif).weight(.medium))
                            .lineSpacing(6)
                            .foregroundStyle(Color.textPrimary)

                        Divider()

                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.textSecondary)
                            Text(question.choices[question.answerIndex])
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.accent)
                        }
                    }
                }

                // 解き方の流れ（トグル）
                sectionCard {
                    DisclosureGroup(isExpanded: $explanationExpanded) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(.init(question.explanation))
                                .font(.system(size: 14))
                                .foregroundStyle(Color.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 10)

                            Button {
                                showAssistantSheet = true
                                if assistantText == nil {
                                    Task { await loadAssistant() }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 10))
                                    Text(assistantText == nil ? "もっと解説" : "詳細な解説を見る")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundStyle(Color.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.textSecondary.opacity(0.08))
                                .clipShape(Capsule())
                            }
                            .disabled(isLoadingAssistant)
                        }
                    } label: {
                        labelWithIcon("解き方の流れ", icon: "lightbulb")
                    }
                    .tint(Color.textSecondary)
                }

                // 各選択肢の解説
                sectionCard {
                    VStack(alignment: .leading, spacing: 14) {
                        labelWithIcon("各選択肢の解説", icon: "list.bullet")
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(question.choices.enumerated()), id: \.offset) { i, choice in
                                let correct = i == question.answerIndex
                                let reason = i < question.choiceExplanations.count
                                    ? question.choiceExplanations[i] : ""
                                VStack(alignment: .leading, spacing: 3) {
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
                                    Text(reason)
                                        .font(.system(size: 12))
                                        .lineSpacing(4)
                                        .foregroundStyle(Color.textSecondary)
                                        .padding(.leading, 24)
                                }
                                .padding(.vertical, 10)

                                if i < question.choices.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                // 次へボタン
                Button(action: onNext) {
                    Text(isLast ? "結果を見る" : "次の問題へ")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.appBackground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .contentShape(Rectangle())
                    .background(Color.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.top, 4)

                Spacer().frame(height: 32)
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showAssistantSheet) {
            AssistantSheetView(
                isLoading: isLoadingAssistant,
                text: assistantText,
                assistantBeat: $assistantBeat
            )
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Assistant

    private func loadAssistant() async {
        isLoadingAssistant = true

        if forPreview {
            try? await Task.sleep(for: .milliseconds(800))
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                assistantText = "**ステップ1：** 条件を整理します。ア > イ、イ > ウ、ウ > エ。\n\n**ステップ2：** 順序を繋げます。ア > イ > ウ > エ の順が確定します。\n\n**結論：** 1位はア、**2位はイ**、3位はウ、4位はエです。"
                isLoadingAssistant = false
            }
            return
        }

        guard let apiKey = KeychainManager.load(for: .gemini) else {
            isLoadingAssistant = false
            return
        }
        let prompt = """
        以下のSPI推論問題について、初めて解く人にも理解できるよう、丁寧にステップごとに解説してください。
        必要な箇所に**太字**と改行のみ使用してください。#や##などの見出し記号は絶対に使わないでください。日本語で答えてください。

        問題：\(question.text)
        正解：\(question.choices[question.answerIndex])
        """
        do {
            let raw = try await GeminiService().generateText(prompt: prompt, apiKey: apiKey)
            let cleaned = raw
                .replacingOccurrences(of: #"#{1,6}\s?"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                assistantText = cleaned
                isLoadingAssistant = false
            }
        } catch {
            isLoadingAssistant = false
        }
    }

    // MARK: - Helpers

    private func labelWithIcon(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .tracking(0.5)
        }
    }

    @ViewBuilder
    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Assistant Sheet

private struct AssistantSheetView: View {
    let isLoading: Bool
    let text: String?
    @Binding var assistantBeat: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
                Text("詳細な解説")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .tracking(0.3)
            }
            .padding(.top, 28)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)

            Divider()

            if isLoading {
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.textSecondary)
                            .frame(width: 6, height: 6)
                            .offset(y: assistantBeat ? -5 : 5)
                            .animation(
                                .easeInOut(duration: 0.45)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.15),
                                value: assistantBeat
                            )
                    }
                    Text("解説を生成中")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
                .onAppear { assistantBeat = true }
                .onDisappear { assistantBeat = false }
            }

            if let text {
                ScrollView {
                    Text(.init(text))
                        .font(.system(size: 15))
                        .lineSpacing(7)
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .padding(.bottom, 20)
                }
            }

            Spacer()
        }
        .background(Color.cardBackground)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        ExplanationView(
            question: MockAIService.sampleQuestions[0],
            questionNumber: 1,
            selectedIndex: 2,
            isLast: false,
            onNext: {},
            forPreview: true
        )
    }
}
