
//  HomeView.swift
//  Suiron

import SwiftUI

// MARK: - BookEmoji Model

private struct BookEmoji: Identifiable {
    let id = UUID()
    let symbol: String
    let x: CGFloat
    let size: CGFloat
    let rotation: Double
    let duration: Double
    let delay: Double

    static func generate(count: Int, screenWidth: CGFloat) -> [BookEmoji] {
        let symbols = ["📚", "📖", "📝", "📓", "📒", "📕", "📗"]
        return (0..<count).map { i in
            BookEmoji(
                symbol: symbols[i % symbols.count],
                x: CGFloat.random(in: 32...(screenWidth - 32)),
                size: CGFloat.random(in: 36...52),
                rotation: Double.random(in: -15...15),
                duration: Double.random(in: 1.5...2.5),
                delay: Double.random(in: 0...1.5)
            )
        }
    }
}

// MARK: - Falling Emoji View

private struct FallingEmojiView: View {
    let emoji: BookEmoji
    let screenHeight: CGFloat
    @State private var falling = false

    var body: some View {
        Text(emoji.symbol)
            .font(.system(size: emoji.size))
            .rotationEffect(.degrees(emoji.rotation))
            .position(x: emoji.x, y: falling ? screenHeight + 100 : -100)
            .animation(
                .easeIn(duration: emoji.duration)
                    .repeatForever(autoreverses: false)
                    .delay(emoji.delay),
                value: falling
            )
            .onAppear { falling = true }
    }
}

// MARK: - HomeView

struct HomeView: View {
    @State private var setupViewModel = SetupViewModel()
    @State private var showSetup = false
    @State private var bookEmojis = BookEmoji.generate(count: 7, screenWidth: 390)
    @State private var screenSize: CGSize = CGSize(width: 390, height: 844)
    @State private var buttonScale: CGFloat = 1.0
    @State private var circleScale: CGFloat = 0
    @State private var showQuiz = false
    @State private var hapticTrigger = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 10) {
                Text("Suiron")
                    .font(.system(size: 36, design: .serif).weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("Create speculation test for SPI by AI...")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()

            Button {
                Task { await startQuiz() }
            } label: {
                HStack(spacing: 8) {
                    Text("Start")
                        .font(.system(size: 17, weight: .semibold))
                    Text("😑")
                }
                .foregroundStyle(.white)
                .frame(width: 280, height: 52)
                .background(Color.accent)
                .clipShape(Capsule())
            }
            .scaleEffect(buttonScale)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: hapticTrigger)

            Spacer().frame(height: 160)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                GeometryReader { geo in
                    ZStack {
                        ForEach(bookEmojis) { emoji in
                            FallingEmojiView(emoji: emoji, screenHeight: geo.size.height)
                        }
                    }
                    .onAppear {
                        screenSize = geo.size
                        bookEmojis = BookEmoji.generate(count: 7, screenWidth: geo.size.width)
                    }
                }
                .allowsHitTesting(false)
            }
        }
        .overlay {
            let d = max(screenSize.width, screenSize.height) * 3
            Circle()
                .fill(Color.black)
                .frame(width: d, height: d)
                .scaleEffect(circleScale)
                .allowsHitTesting(false)
        }
        .task {
            // task はビュー表示後に確実に実行される
            setupViewModel.loadSavedKey()
            showSetup = !setupViewModel.isSetupComplete
        }
        .onChange(of: setupViewModel.isSetupComplete) { _, done in
            if done { showSetup = false }
        }
        .sheet(isPresented: $showSetup) {
            SetupSheetView(viewModel: setupViewModel)
                .presentationDetents([.large])
                .interactiveDismissDisabled(true)
        }
        .fullScreenCover(isPresented: $showQuiz) {
            QuizView(onDismiss: { showQuiz = false })
        }
    }

    private func startQuiz() async {
        hapticTrigger.toggle()
        withAnimation(.easeInOut(duration: 0.1)) { buttonScale = 0.95 }
        try? await Task.sleep(for: .milliseconds(100))
        withAnimation(.easeInOut(duration: 0.35)) { circleScale = 1.0 }
        try? await Task.sleep(for: .milliseconds(400))
        showQuiz = true
        circleScale = 0
        buttonScale = 1.0
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
