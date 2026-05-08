
//  AppError.swift
//  Suiron

import Foundation

enum AppError: LocalizedError {
    case apiKeyMissing
    case networkError(underlying: Error)
    case invalidResponse
    case jsonParseError
    case unknown

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
        case .unknown:
            return "不明なエラーが発生しました。"
        }
    }
}
