
//  DifficultyLevel.swift
//  Suiron

import Foundation

enum DifficultyLevel: String, CaseIterable {
    case normal = "ふつう"
    case hard   = "むずかしい"

    var symbol: String {
        switch self {
        case .normal: return "book.fill"
        case .hard:   return "flame.fill"
        }
    }

    var promptDescription: String {
        switch self {
        case .normal:
            return "ふつう（就活生が練習で解くレベル。条件3〜4個、推論2〜3ステップ）"
        case .hard:
            return "むずかしい（条件5〜6個、推論4〜5ステップ必要な発展レベル。問題文が長く、情報の整理に手間がかかる問題を出すこと）"
        }
    }
}
