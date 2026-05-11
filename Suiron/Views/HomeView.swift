
//  HomeView.swift
//  Suiron

import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    @State private var setupViewModel = SetupViewModel()
    @State private var showSetup = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var circleScale: CGFloat = 0
    @State private var showQuiz = false
    @State private var hapticTrigger = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 上部ナビゲーション
                HStack {
                    Spacer()
                    Button { showSetup = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 12)

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

                VStack(spacing: 16) {
                    Button {
                        Task { await startQuiz() }
                    } label: {
                        HStack(spacing: 8) {
                            Text("Start")
                                .font(.system(size: 17, weight: .semibold))
                            Text("😑")
                        }
                        .foregroundStyle(Color.appBackground)
                        .frame(width: 280, height: 52)
                        .background(Color.accent)
                        .clipShape(Capsule())
                    }
                    .scaleEffect(buttonScale)
                    .sensoryFeedback(.impact(flexibility: .soft), trigger: hapticTrigger)
                }

                Spacer().frame(height: 220)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground.ignoresSafeArea())

            // QuizView（黒丸の下に即座に配置）
            if showQuiz {
                QuizView(onDismiss: {
                    withAnimation(.easeIn(duration: 0.25)) { circleScale = 1.0 }
                    Task {
                        try? await Task.sleep(for: .milliseconds(280))
                        showQuiz = false
                        withAnimation(.easeOut(duration: 0.3)) { circleScale = 0 }
                    }
                })
            }

            // 黒丸（常に最前面）
            GeometryReader { geo in
                let d = max(geo.size.width, geo.size.height) * 3
                Circle()
                    .fill(Color.black)
                    .frame(width: d, height: d)
                    .scaleEffect(circleScale)
                    .allowsHitTesting(false)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .ignoresSafeArea()

        } // ZStack end
        .task {
            setupViewModel.loadSavedKey()
            showSetup = !setupViewModel.isSetupComplete
        }
        .onChange(of: setupViewModel.isSetupComplete) { _, done in
            if done { showSetup = false }
        }
        .sheet(isPresented: $showSetup) {
            SetupSheetView(viewModel: setupViewModel)
                .presentationDetents([.large])
                .interactiveDismissDisabled(!setupViewModel.isSetupComplete)
        }
    }

    private func startQuiz() async {
        hapticTrigger.toggle()
        withAnimation(.easeInOut(duration: 0.1)) { buttonScale = 0.95 }
        try? await Task.sleep(for: .milliseconds(100))
        withAnimation(.easeInOut(duration: 0.35)) { circleScale = 1.0 }
        try? await Task.sleep(for: .milliseconds(400))
        showQuiz = true
        try? await Task.sleep(for: .milliseconds(80))
        withAnimation(.easeOut(duration: 0.3)) { circleScale = 0 }
        buttonScale = 1.0
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
