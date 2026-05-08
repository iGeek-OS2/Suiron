
//  SetupViewModel.swift
//  Suiron

import SwiftUI

@MainActor
@Observable
class SetupViewModel {
    var apiKey: String = ""
    var errorMessage: String? = nil

    private let provider: AIProvider = .gemini
    private let setupCompleteKey = "setupComplete"

    var canProceed: Bool {
        !apiKey.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var isSetupComplete: Bool

    // UserDefaults が true かつ Keychain にAPIキーが存在する場合のみ setup 完了とみなす
    init() {
        let flagged = UserDefaults.standard.bool(forKey: "setupComplete")
        let hasKey  = KeychainManager.load(for: .gemini) != nil
        self.isSetupComplete = flagged && hasKey
    }

    func save() {
        do {
            try KeychainManager.save(apiKey.trimmingCharacters(in: .whitespaces), for: provider)
            UserDefaults.standard.set(true, forKey: setupCompleteKey)
            isSetupComplete = true
        } catch {
            errorMessage = AppError.unknown.errorDescription
        }
    }

    func loadSavedKey() {
        apiKey = KeychainManager.load(for: provider) ?? ""
    }

    func reset() {
        KeychainManager.delete(for: provider)
        UserDefaults.standard.set(false, forKey: setupCompleteKey)
        isSetupComplete = false
        apiKey = ""
    }
}
