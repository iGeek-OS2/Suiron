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
| Gemini | Gemini | `gemini-3.1-flash` | https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash:generateContent |

> **現在の実装対象**: Gemini のみ。OpenAI（gpt-5.5）・Claude（claude-sonnet-4-6）は将来追加予定。
> SetupSheetView のAI選択UIも現時点では Gemini の1択にしておくこと。

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

### システムプロンプト
```
あなたは日本の就活SPI試験の問題作成の専門家です。
本物のSPIに出題される推論問題のみを作成してください。

【出題する問題の8パターン】
以下の8種類からランダムに組み合わせて出題すること（5問で偏りが出ないよう分散させる）：
1. 順序：複数人の順位・順番を条件から特定する（例：テストの成績順）
2. 対応：人物と属性（出身地・担当・趣味など）の組み合わせを表で推理する
3. 整数：カードの数・人数・数の組み合わせを条件から推測する（最頻出）
4. 位置関係：席・位置・方向を「AはBの右隣」などの条件から確定させる
5. 内訳・割合：集合の内訳や割合を条件から推理する
6. 対戦：勝敗の結果から順位や未知の対戦結果を推理する
7. 正誤判断：複数の条件をもとに選択肢の文章が正しいか誤っているかを判断する
8. 情報の信頼性：複数の情報の一部が誤りである場合に成立する組み合わせを推理する

【禁止事項】
- 選択肢の番号・文字と問題中の人物名を同じにしない
- 正解が複数存在する問題は出題しない（必ず答えが一意に決まること）
- 問題を作成したら、正解が本当に一意かを自分で検証してから出力する
- 同じパターンを連続して3問以上出題しない
```

### ユーザープロンプト
```
上記の条件でSPI推論問題を5問作成してください。
難易度：普通（就活生が練習で解くレベル）。
以下のJSON配列のみを返してください。前置き・説明文・コードブロック記号は不要です。

[
  {
    "text": "問題文（登場人物はア・イ・ウ・エなどカタカナを使うこと）",
    "choices": ["選択肢1の文章","選択肢2の文章","選択肢3の文章","選択肢4の文章"],
    "answerIndex": 0,
    "explanation": "なぜその選択肢が正解なのか、そして解き方の流れをわかりやすく解説"
  }
]
```

## セットアップ画面の仕様
- **表示方法**: `.sheet(isPresented:)` + `.presentationDetents([.large])`
- **閉じる制御**: `.interactiveDismissDisabled(true)`（設定完了前は閉じ不可）
- **表示タイミング**: `setupComplete == false` の場合、HomeView表示時に自動で出現
- **保存先**: 選択AIは `UserDefaults`、APIキーは `Keychain`

## ビルドルール（必須）
- コードを編集したら **必ず** 以下のコマンドでビルドを実行すること
  ```
  xcodebuild -scheme Suiron -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E 'error:|Build succeeded|Build FAILED'
  ```
- ビルドエラーが出た場合はそのまま自動修正し、再度ビルドが成功するまで繰り返すこと
- SourceKit（LSP）の警告はビルドエラーではないため無視してよい

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
