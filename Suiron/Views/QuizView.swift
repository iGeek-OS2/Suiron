
//  QuizView.swift
//  Suiron

import SwiftUI

// MARK: - Choice State

private struct ChoiceDisplayState {
    let background: Color
    let border: Color
    let borderWidth: CGFloat
    let badgeBackground: Color
    let icon: String?
    let iconColor: Color

    static let idle = ChoiceDisplayState(
        background: .cardBackground,
        border: .clear, borderWidth: 0,
        badgeBackground: .accent,
        icon: nil, iconColor: .clear
    )
    static let correct = ChoiceDisplayState(
        background: .correctBg,
        border: .correct, borderWidth: 2,
        badgeBackground: .correct,
        icon: "checkmark", iconColor: .correct
    )
    static let incorrect = ChoiceDisplayState(
        background: .incorrectBg,
        border: .incorrect, borderWidth: 2,
        badgeBackground: .incorrect,
        icon: "xmark", iconColor: .incorrect
    )
    static let revealCorrect = ChoiceDisplayState(
        background: .correctBg,
        border: .correct, borderWidth: 2,
        badgeBackground: .correct,
        icon: "checkmark", iconColor: .correct
    )
}

// MARK: - QuizView

struct QuizView: View {
    let onDismiss: () -> Void

    @State private var viewModel = QuizViewModel()
    @State private var cursorVisible = true
    @State private var successHaptic = false
    @State private var errorHaptic = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            switch viewModel.quizState {
            case .loading:
                loadingView
            case .quiz:
                quizContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                    .id("quiz-\(viewModel.currentIndex)")
            case .explanation:
                if let question = viewModel.currentQuestion,
                   let selected = viewModel.selectedIndex {
                    ExplanationView(
                        question: question,
                        selectedIndex: selected,
                        isLast: viewModel.currentIndex + 1 >= viewModel.questions.count,
                        onNext: { Task { await viewModel.advance() } }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                    .id("explanation-\(viewModel.currentIndex)")
                }
            case .finished:
                ResultView(
                    questions: viewModel.questions,
                    userAnswers: viewModel.userAnswers,
                    onPlayAgain: onDismiss
                )
            case .error(let error):
                errorView(error)
            }
        }
        .task { await viewModel.start() }
        .sensoryFeedback(.success, trigger: successHaptic)
        .sensoryFeedback(.error,   trigger: errorHaptic)
        .onChange(of: viewModel.selectedIndex) { _, newValue in
            guard let selected = newValue,
                  let question = viewModel.currentQuestion else { return }
            if selected == question.answerIndex {
                successHaptic.toggle()
            } else {
                errorHaptic.toggle()
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
            Text("問題を生成中...")
                .font(.system(size: 15))
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - Error

    private func errorView(_ error: AppError) -> some View {
        VStack(spacing: 20) {
            Text("エラーが発生しました")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            Text(error.localizedDescription)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("もう一度試す") {
                Task { await viewModel.start() }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 200, height: 48)
            .background(Color.accent)
            .clipShape(Capsule())
        }
    }

    // MARK: - Quiz Content

    private var quizContent: some View {
        VStack(spacing: 0) {
            progressBar

            ScrollView {
                VStack(alignment: .trailing, spacing: 16) {
                    progressBadge
                        .padding(.trailing, 20)
                        .padding(.top, 16)

                    questionCard
                        .padding(.horizontal, 20)

                    if let question = viewModel.currentQuestion {
                        choicesView(question: question)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .task(id: viewModel.isTyping) {
            if viewModel.isTyping {
                do {
                    repeat {
                        cursorVisible.toggle()
                        try await Task.sleep(for: .milliseconds(500))
                    } while viewModel.isTyping
                } catch {}
            }
            cursorVisible = false
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(Color.accent)
                .frame(width: geo.size.width * viewModel.progress, height: 3)
                .animation(.easeInOut(duration: 0.35), value: viewModel.progress)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 3)
    }

    // MARK: - Progress Badge

    private var progressBadge: some View {
        Text("\(viewModel.currentIndex + 1) / \(viewModel.questions.count)")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(hex: "#E0E0E0"))
            .clipShape(Capsule())
    }

    // MARK: - Question Card

    private var questionCard: some View {
        let cursor = viewModel.isTyping && cursorVisible ? "|" : ""
        return Text(viewModel.displayedText + cursor)
            .font(.system(size: 16))
            .lineSpacing(6)
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Choices

    private func choicesView(question: Question) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(question.choices.enumerated()), id: \.offset) { index, choice in
                choiceButton(index: index, text: choice, question: question)
                    .opacity(viewModel.showChoices ? 1 : 0)
                    .offset(y: viewModel.showChoices ? 0 : 40)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.8)
                            .delay(Double(index) * 0.08),
                        value: viewModel.showChoices
                    )
            }
        }
    }

    private func choiceButton(index: Int, text: String, question: Question) -> some View {
        let s = displayState(index: index, question: question)

        return Button {
            Task { await viewModel.select(index: index) }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(s.badgeBackground)
                        .frame(width: 28, height: 28)
                    Text("\(index + 1)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text(text)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(0.8)

                if let icon = s.icon {
                    Image(systemName: icon)
                        .foregroundStyle(s.iconColor)
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(s.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(s.border, lineWidth: s.borderWidth)
            }
        }
        .disabled(viewModel.selectedIndex != nil)
        .accessibilityLabel("選択肢\(index + 1): \(text)")
    }

    // MARK: - Display State

    private func displayState(index: Int, question: Question) -> ChoiceDisplayState {
        guard let selected = viewModel.selectedIndex else { return .idle }
        let isCorrect = index == question.answerIndex
        let isSelected = index == selected
        if isSelected && isCorrect  { return .correct }
        if isSelected && !isCorrect { return .incorrect }
        if !isSelected && isCorrect { return .revealCorrect }
        return .idle
    }
}

// MARK: - Preview

#Preview {
    QuizView(onDismiss: {})
}
