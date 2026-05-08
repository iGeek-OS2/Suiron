# Suiron — Claude Code Instructions

## プロジェクト概要
就活SPI推論問題をAIが5問生成するiOSミニアプリ。
アニメーションとデザインにこだわったシンプル構成。

## 技術スタック
- **言語**: Swift 5.9+
- **UI**: SwiftUI（iOS 17以上）
- **状態管理**: Combine + @Observable (iOS 17)
- **データ保存**: UserDefaults（設定）/ Keychain（APIキー）
- **対応デバイス**: iPhone（iPadはセンタリング対応）

## 対応AI
| プロバイダー | 表示名 | APIモデル文字列 | エンドポイント |
|---|---|---|---|
| OpenAI | ChatGPT | `gpt-5.4-mini` | https://api.openai.com/v1/chat/completions |
| Gemini | Gemini | `gemini-3.1-flash-lite` | https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent |
| Claude | Claude | `claude-sonnet-4-6` | https://api.anthropic.com/v1/messages |

> **モデル選定理由**: 問題生成（テキストのみ）はミニアプリ用途のため、コスト・レイテンシ重視の軽量モデルを採用。
> - GPT-5.5（最上位）ではなく `gpt-5.4-mini`（高速・低コスト）
> - Gemini 3.1 Pro Previewではなく `gemini-3.1-flash-lite`（最軽量・最安価）
> - Claude Sonnet 4.6（`claude-sonnet-4-6`）はコスト/性能バランスが最良のため採用
>
> ユーザーが上位モデルに切り替えたい場合は将来的に設定画面で選択できるよう拡張可能にしておくこと。

## 画面構成
```
App起動
 └─ HomeView（メイン画面）
     ├─ SetupSheet（初回のみ、下からシート表示）
     ├─ [Start] → QuizView
     └─ QuizView → ResultView
```

## ファイル構成
```
Suiron/
├── App/
│   └── SuironApp.swift
├── Models/
│   ├── AIProvider.swift       # OpenAI / Gemini / Claude 列挙型
│   ├── Question.swift         # 問題モデル
│   └── AppError.swift
├── Services/
│   ├── AIServiceProtocol.swift
│   ├── OpenAIService.swift
│   ├── GeminiService.swift
│   ├── ClaudeService.swift
│   └── MockAIService.swift    # テスト用
├── ViewModels/
│   ├── SetupViewModel.swift
│   └── QuizViewModel.swift
├── Views/
│   ├── HomeView.swift
│   ├── SetupSheetView.swift
│   ├── QuizView.swift
│   └── ResultView.swift
└── Utilities/
    └── KeychainManager.swift
```

## データモデル

### Question
```swift
struct Question: Identifiable, Codable {
    let id: UUID
    let text: String           // 問題文
    let choices: [String]      // 選択肢（4択）
    let answerIndex: Int       // 正解のindex（0始まり）
    let explanation: String    // 解説
}
```

### AIProvider
```swift
enum AIProvider: String, CaseIterable {
    case openai = "ChatGPT"
    case gemini = "Gemini"
    case claude = "Claude"
}
```

## AI問題生成プロンプト（共通）
```
就活SPIの推論問題（発言の真偽を推理するタイプ）を5問作成してください。
難易度：普通。
以下のJSON配列のみを返してください。説明文は不要です。

[
  {
    "text": "問題文",
    "choices": ["選択肢A","選択肢B","選択肢C","選択肢D"],
    "answerIndex": 0,
    "explanation": "解説文"
  }
]
```

## セットアップ画面の仕様
- **表示方法**: `.sheet(isPresented:)` + `.presentationDetents([.large])`
- **閉じる制御**: `.interactiveDismissDisabled(true)`（設定完了前は閉じ不可）
- **表示タイミング**: `setupComplete == false` の場合、HomeView表示時に自動で出現
- **保存先**: 選択AIは `UserDefaults`、APIキーは `Keychain`

## コーディングルール
- `async/await` を使用（コールバック・Combineは使わない）
- `@MainActor` をViewModelに付与
- エラーはすべて `AppError` に統一
- Magic numberは定数化（`Constants.swift` or `extension` で管理）
- SwiftUI Previewは各Viewに必ず追加（MockAIServiceを使用）
- コメントは日本語OK

## やってはいけないこと
- APIキーを UserDefaults や `print()` に出力しない
- ハードコードされたAPIキーをコードに含めない
- force unwrap（`!`）を使わない
- MainThread以外でのUI更新

## 開発の進め方
実装は以下の順番で進める。各フェーズ完了後に確認を求めること。

1. `Phase 0` — モデル定義 + フォルダ構成
2. `Phase 1` — APIサービス層（Mock含む）
3. `Phase 2` — SetupSheetView
4. `Phase 3` — HomeView + 落下アニメーション
5. `Phase 4` — QuizView + タイプライター
6. `Phase 5` — ResultView + 仕上げ

各フェーズ完了時：「✅ Phase X 完了。次に進みますか？」と確認すること。
