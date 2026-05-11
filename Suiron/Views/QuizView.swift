
//  QuizView.swift
//  Suiron

import SwiftUI
import PencilKit

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
        background: .cardBackground,
        border: .textPrimary, borderWidth: 2,
        badgeBackground: .textPrimary,
        icon: "checkmark", iconColor: .textPrimary
    )
    static let incorrect = ChoiceDisplayState(
        background: .cardBackground,
        border: .textPrimary, borderWidth: 2,
        badgeBackground: .textSecondary,
        icon: nil, iconColor: .clear
    )
    static let revealCorrect = ChoiceDisplayState(
        background: .cardBackground,
        border: .textPrimary, borderWidth: 2,
        badgeBackground: .textPrimary,
        icon: "checkmark", iconColor: .textPrimary
    )
}

// MARK: - Compile Loading View

private struct ThreeDotsView: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.textPrimary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(phase == i ? 1.4 : 1.0)
                    .opacity(phase == i ? 1.0 : 0.35)
                    .animation(.easeInOut(duration: 0.4), value: phase)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
    }
}

private struct CompileLoadingView: View {
    let streamingText: String

    private var statusText: String {
        if streamingText.isEmpty {
            return "AIにプロンプトを送信中..."
        } else {
            return "レスポンスを受信中... (\(streamingText.count)文字)"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            ThreeDotsView()
            VStack(spacing: 7) {
                Text("問題を生成中")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(statusText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }
}

// MARK: - Shake Effect

private struct ShakeEffect: GeometryEffect {
    var amount: CGFloat
    var animatableData: CGFloat {
        get { amount }
        set { amount = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        .init(CGAffineTransform(translationX: 9 * sin(amount * .pi * 5), y: 0))
    }
}

// MARK: - QuizView

struct QuizView: View {
    let onDismiss: () -> Void
    var forPreview: Bool = false

    @State private var viewModel = QuizViewModel()
    @State private var cursorVisible = true
    @State private var successHaptic = false
    @State private var errorHaptic = false
    @State private var textRevealHaptic = false
    @State private var shakeProgress: CGFloat = 0
    @State private var correctPulse: CGFloat = 1.0
    @State private var isMemoPresented = false
    @State private var memoDrawing = PKDrawing()
    @State private var memoDetent: PresentationDetent = .fraction(0.45)

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
                        questionNumber: viewModel.currentIndex + 1,
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

            // メモボタン（quiz状態のみ）
            if case .quiz = viewModel.quizState {
                memoButton
            }

        }
        .sheet(isPresented: $isMemoPresented) {
            MemoSheetView(drawing: $memoDrawing)
                .presentationDetents([.fraction(0.45), .large], selection: $memoDetent)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.45)))
        }
        .onChange(of: viewModel.currentIndex) { _, _ in
            memoDrawing = PKDrawing()
            isMemoPresented = false
        }
        .task {
            if forPreview { viewModel.loadPreview() }
            else { await viewModel.start() }
        }
        .sensoryFeedback(.success, trigger: successHaptic)
        .sensoryFeedback(.error,   trigger: errorHaptic)
        .sensoryFeedback(.impact(weight: .light), trigger: textRevealHaptic)
        .onChange(of: viewModel.isTyping) { _, isTyping in
            if !isTyping, case .quiz = viewModel.quizState {
                textRevealHaptic.toggle()
            }
        }
        .onChange(of: viewModel.selectedIndex) { _, newValue in
            guard let selected = newValue,
                  let question = viewModel.currentQuestion else { return }
            if selected == question.answerIndex {
                successHaptic.toggle()
                withAnimation(.spring(response: 0.25, dampingFraction: 0.35)) {
                    correctPulse = 1.07
                }
                Task {
                    try? await Task.sleep(for: .milliseconds(200))
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                        correctPulse = 1.0
                    }
                }
            } else {
                errorHaptic.toggle()
                withAnimation(.linear(duration: 0.45)) {
                    shakeProgress = 1
                }
                Task {
                    try? await Task.sleep(for: .milliseconds(450))
                    shakeProgress = 0
                }
            }
        }
    }

    // MARK: - Memo Button

    private var memoButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    memoDetent = .fraction(0.45)
                    isMemoPresented = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                        .frame(width: 52, height: 52)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 48)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Loading

    private var loadingView: some View {
        CompileLoadingView(streamingText: viewModel.loadingText)
    }

    // MARK: - Error

    private func errorView(_ error: AppError) -> some View {
        let isRateLimit = error == .rateLimitError
        return VStack(spacing: 20) {
            Text("エラーが発生しました")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            Text(error.localizedDescription)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if isRateLimit {
                Button("ホームに戻る") { onDismiss() }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appBackground)
                    .frame(width: 200, height: 48)
                    .background(Color.accent)
                    .clipShape(Capsule())
            } else {
                Button("もう一度試す") {
                    Task { await viewModel.start() }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.appBackground)
                .frame(width: 200, height: 48)
                .background(Color.accent)
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Quiz Content

    private var quizContent: some View {
        VStack(spacing: 0) {
            progressBar

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    questionHeading
                        .padding(.horizontal, 20)
                        .padding(.top, 40)

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
                    let letters = ["A", "B", "C", "D"]
                    Text(index < letters.count ? letters[index] : "\(index + 1)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.appBackground)
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
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(s.border, lineWidth: s.borderWidth)
            }
        }
        .disabled(viewModel.selectedIndex != nil)
        .modifier(ShakeEffect(amount: (viewModel.selectedIndex == index && index != question.answerIndex) ? shakeProgress : 0))
        .scaleEffect((viewModel.selectedIndex == index && index == question.answerIndex) ? correctPulse : 1.0)
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

    // MARK: - Question Heading

    private static let kanjiNumbers = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]

    private var questionHeading: some View {
        let kanji = viewModel.currentIndex < Self.kanjiNumbers.count
            ? Self.kanjiNumbers[viewModel.currentIndex] : "\(viewModel.currentIndex + 1)"
        return Text("問題\(kanji)")
            .font(.system(size: 30, design: .serif).weight(.bold))
            .foregroundStyle(Color.textPrimary)
    }

    // MARK: - Question Card

    private var questionCard: some View {
        let cursor = viewModel.isTyping && cursorVisible ? "|" : ""
        return Text(viewModel.displayedText + cursor)
            .font(.system(size: 14, design: .serif).weight(.medium))
            .lineSpacing(6)
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }

}

// MARK: - Preview

#Preview("Quiz") {
    QuizView(onDismiss: {}, forPreview: true)
}

