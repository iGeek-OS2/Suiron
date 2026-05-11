
//  SetupSheetView.swift
//  Suiron

import SwiftUI

struct SetupSheetView: View {
    @Bindable var viewModel: SetupViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    @State private var hapticTrigger = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 48)

            // タイトル
            VStack(spacing: 8) {
                Text("Suiron へようこそ")
                    .font(.system(.title2, design: .serif).weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                Text("Gemini の APIキーを入力してください")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.easeOut(duration: 0.3), value: appeared)

            Spacer().frame(height: 40)

            // Geminiバッジ
            HStack(spacing: 12) {
                Text("✦")
                    .font(.system(size: 22))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gemini")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text("Google")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.accent)
                    .font(.system(size: 20))
            }
            .padding(16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.accent, lineWidth: 2)
            )
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.easeOut(duration: 0.3).delay(0.08), value: appeared)

            Spacer().frame(height: 16)

            // APIキー入力欄
            VStack(alignment: .leading, spacing: 8) {
                Text("APIキー")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textSecondary)

                SecureField("AIzaSy...", text: $viewModel.apiKey)
                    .padding(14)
                    .background(Color.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .font(.system(size: 15, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.incorrect)
                }

                Link(destination: URL(string: "https://aistudio.google.com/")!) {
                    HStack(spacing: 4) {
                        Text("APIキーを取得する")
                            .font(.system(size: 12))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.easeOut(duration: 0.3).delay(0.16), value: appeared)

            Spacer()

            // はじめるボタン
            Button {
                hapticTrigger.toggle()
                viewModel.save()
                if viewModel.isSetupComplete { dismiss() }
            } label: {
                Text("はじめる")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.appBackground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            .disabled(!viewModel.canProceed)
            .opacity(viewModel.canProceed ? 1.0 : 0.4)
            .animation(.easeInOut(duration: 0.1), value: viewModel.canProceed)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.easeOut(duration: 0.3).delay(0.24), value: appeared)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: hapticTrigger)
        }
        .background(Color.cardBackground.ignoresSafeArea())
        .onAppear { appeared = true }
    }
}

#Preview {
    SetupSheetView(viewModel: SetupViewModel())
}
