
//  AppError.swift
//  Suiron

import Foundation

enum AppError: LocalizedError, Equatable {
    case apiKeyMissing
    case networkError(underlying: Error)
    case invalidResponse
    case jsonParseError
    case rateLimitError
    case unknown

    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.apiKeyMissing, .apiKeyMissing),
             (.invalidResponse, .invalidResponse),
             (.jsonParseError, .jsonParseError),
             (.rateLimitError, .rateLimitError),
             (.unknown, .unknown): return true
        case (.networkError, .networkError): return true
        default: return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "APIキーが設定されていません。"
        case .networkError(let error):
            return "通信エラー: \(error.localizedDescription)"
        case .invalidResponse:
            return "サーバーから無効なレスポンスが返されました。"
        case .jsonParseError:
            return "問題データの解析に失敗しました。"
        case .rateLimitError:
            return "APIのレート制限に達しました。しばらく待ってから再試行してください。"
        case .unknown:
            return "不明なエラーが発生しました。"
        }
    }
}
