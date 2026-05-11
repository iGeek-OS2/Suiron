
//  AIProvider.swift
//  Suiron

import Foundation

enum GeminiModel: String {
    case flash = "gemini-3-flash-preview"

    var baseURL: String {
        "https://generativelanguage.googleapis.com/v1beta/models/\(rawValue)"
    }
}

enum AIProvider: String, CaseIterable, Identifiable, Codable {
    case openai = "ChatGPT"
    case gemini = "Gemini"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var subLabel: String {
        switch self {
        case .openai: return "OpenAI"
        case .gemini: return "Google"
        }
    }

    var modelID: String {
        switch self {
        case .openai: return "gpt-5.4-mini"
        case .gemini: return "gemini-3-flash-preview"
        }
    }

    var endpoint: URL {
        switch self {
        case .openai:
            return URL(string: "https://api.openai.com/v1/chat/completions")!
        case .gemini:
            return URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent")!
        }
    }
}
