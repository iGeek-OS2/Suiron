
//  QuizViewModel.swift
//  Suiron

import SwiftUI

@MainActor
@Observable
class QuizViewModel {

    enum QuizState {
        case loading
        case quiz
        case explanation
        case finished
        case error(AppError)
    }

    var quizState: QuizState = .loading
    var questions: [Question] = []
    var currentIndex: Int = 0
    var selectedIndex: Int? = nil
    var userAnswers: [Int] = []
    var loadingText: String = ""
    var displayedText: String = ""
    var isTyping: Bool = false
    var showChoices: Bool = false

    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(questions.count)
    }

    // MARK: - プレビュー用

    func loadPreview() {
        questions = MockAIService.sampleQuestions
        currentIndex = 0
        displayedText = questions[0].text
        showChoices = true
        quizState = .quiz
    }

    // MARK: - 開始・リトライ

    func start() async {
        let difficulty: DifficultyLevel = .normal // プロンプト内では難易度を使わないが型の互換性のため残す
        quizState = .loading
        loadingText = ""
        questions = []
        currentIndex = 0
        userAnswers = []

        guard let apiKey = KeychainManager.load(for: .gemini) else {
            quizState = .error(.apiKeyMissing)
            return
        }

        let validator = QuestionValidator()
        var validQuestions: [Question] = []
        var lastError: Error?

        for attempt in 1...3 {
            guard validQuestions.count < 5 else { break }
            do {
                let service = GeminiService()
                var accumulated = ""
                var lastUpdateCount = 0
                for try await chunk in service.streamRawText(apiKey: apiKey, difficulty: difficulty) {
                    accumulated += chunk
                    if accumulated.count - lastUpdateCount >= 40 {
                        loadingText = accumulated
                        lastUpdateCount = accumulated.count
                    }
                }
                loadingText = accumulated
                let parsed = try parseQuestions(from: accumulated)
                let valid = parsed.filter { validator.validate($0, difficulty: difficulty).isValid }
                validQuestions += valid
            } catch AppError.rateLimitError {
                lastError = AppError.rateLimitError
                if attempt < 3 {
                    let wait = attempt * 10  // 10秒 → 20秒
                    for remaining in stride(from: wait, through: 1, by: -1) {
                        loadingText = "レート制限中... \(remaining)秒後に再試行します"
                        try? await Task.sleep(for: .seconds(1))
                    }
                    loadingText = ""
                }
            } catch {
                lastError = error
                if validQuestions.count < 5 && attempt < 3 {
                    loadingText = ""
                    try? await Task.sleep(for: .seconds(1))
                }
            }
        }

        guard !validQuestions.isEmpty else {
            if let appError = lastError as? AppError {
                quizState = .error(appError)
            } else if let error = lastError {
                quizState = .error(.networkError(underlying: error))
            } else {
                quizState = .error(.jsonParseError)
            }
            return
        }

        questions = Array(validQuestions.prefix(5))
        quizState = .quiz
        await presentQuestion()
    }

    // MARK: - 問題表示（タイプライター）

    func presentQuestion() async {
        guard currentIndex < questions.count else { return }
        selectedIndex = nil
        showChoices = false
        displayedText = ""
        isTyping = true

        for char in questions[currentIndex].text {
            displayedText.append(char)
            do {
                try await Task.sleep(for: .milliseconds(30))
            } catch {
                isTyping = false
                return
            }
        }
        isTyping = false

        do {
            try await Task.sleep(for: .milliseconds(300))
        } catch { return }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showChoices = true
        }
    }

    // MARK: - 選択

    func select(index: Int) async {
        guard selectedIndex == nil else { return }
        selectedIndex = index
        userAnswers.append(index)

        do {
            try await Task.sleep(for: .milliseconds(700))
        } catch { return }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            quizState = .explanation
        }
    }

    // MARK: - 次の問題へ

    func advance() async {
        currentIndex += 1
        if currentIndex >= questions.count {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                quizState = .finished
            }
        } else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                quizState = .quiz
            }
            await presentQuestion()
        }
    }
}
