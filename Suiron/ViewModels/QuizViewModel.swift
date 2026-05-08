
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

    // MARK: - 開始・リトライ

    func start() async {
        quizState = .loading
        questions = []
        currentIndex = 0
        userAnswers = []

        guard let apiKey = KeychainManager.load(for: .gemini) else {
            quizState = .error(.apiKeyMissing)
            return
        }

        do {
            let service = GeminiService()
            questions = try await service.generateQuestions(apiKey: apiKey)
            quizState = .quiz
            await presentQuestion()
        } catch let appError as AppError {
            quizState = .error(appError)
        } catch {
            quizState = .error(.networkError(underlying: error))
        }
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
