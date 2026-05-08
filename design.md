# Suiron — Design Specification

## デザイン方針
- **テーマ**: ミニマル × 遊び心
- **カラーモード**: ライト/ダーク両対応（SwiftUI標準の `colorScheme` 対応）
- **フォント**: システムフォント（SF Pro）。アプリ名のみセリフ体
- **角丸**: 16pt 統一（カード・ボタン）
- **影**: 使用しない（フラットデザイン）
- **最大幅**: 390pt（iPhone基準。iPadは中央寄せ）

---

## カラーパレット

```swift
// ライトモード
background:      #F2F2F2   // 全画面の背景
cardBackground:  #FFFFFF   // カード・モーダル背景
textPrimary:     #1A1A1A
textSecondary:   #888888
accent:          #1A1A1A   // ボタン・選択状態（黒）

// 選択肢フィードバック
correct:         #4CAF50   // 正解（緑）
incorrect:       #F44336   // 不正解（赤）
correctBg:       #E8F5E9
incorrectBg:     #FFEBEE
```

---

## 画面別デザイン仕様

### 1. SetupSheetView（セットアップシート）

**表示方法**: 下からスライドアップするシート（Apple純正スタイル）
```
.sheet(isPresented: $showSetup)
.presentationDetents([.large])
.interactiveDismissDisabled(true)
```

**レイアウト（上から順）**:
```
[上部ハンドル]（表示しない。閉じさせない）
　
[タイトル]「Suiron へようこそ」  24pt / セリフ体
[サブ]「使用するAIを選んでください」  14pt / textSecondary
　
[AIプロバイダー 選択カード × 3]
  ┌─────────────────────────┐
  │  🤖  ChatGPT            │
  │      OpenAI             │
  └─────────────────────────┘
  ※ 選択中: 枠線 2pt / accent色
  ※ 未選択: 枠線 0.5pt / #E0E0E0
　
[APIキー入力欄]
  SecureField「sk-...」
  角丸 12pt / 背景 #F5F5F5
　
[「はじめる」ボタン]
  黒背景 / 白文字 / 角丸 16pt / 高さ 52pt
  ※ APIキー未入力時: opacity 0.4 / disabled
```

**アニメーション**:
- シート表示: SwiftUI標準（変更不要）
- 各要素: `opacity(0→1)` + `offset(y: 20→0)` を 0.08s stagger で
- カード選択: `scaleEffect(1.0 → 1.02 → 1.0)` spring アニメーション

---

### 2. HomeView（ホーム画面）

**背景**: `#F2F2F2`

**レイアウト**:
```
[本の絵文字 × 6〜8個 ランダム配置] ← 降下アニメーション中
　
[中央]
  「Suiron」  36pt / セリフ体（Font.custom or .serif）
  「Create speculation test for SPI by AI...」  13pt / textSecondary
　
[下部]
  ┌───────────────────────────┐
  │  Start 😑                │
  └───────────────────────────┘
  黒背景 / 白文字 / 幅 280pt / 高さ 52pt / 角丸 26pt（pill型）
```

**本の絵文字 落下アニメーション**:
```swift
// 各絵文字のパラメータ（ランダム生成）
struct BookEmoji {
    let x: CGFloat          // 画面幅内のランダムX
    let size: CGFloat       // 36〜52pt
    let rotation: Double    // -15〜15度
    let duration: Double    // 1.5〜2.5s
    let delay: Double       // 0〜1.5s
}

// アニメーション
// Y: -100（画面外上） → screenHeight + 100（画面外下）
// 終端に達したら即座に上に戻して繰り返し（.repeatForever）
// easing: .easeIn（重力感）
```

**Startボタン タップ時の遷移**:
```
1. ボタン scaleEffect: 1.0 → 0.95（0.1s）
2. 黒い円が画面中央から拡大して全画面を覆う（0.35s, easeInOut）
3. QuizView に遷移
```
実装: `GeometryReader` + `clipShape(Circle())` のカスタムトランジション
または `matchedGeometryEffect` でボタンから円へ

---

### 3. QuizView（問題画面）

**背景**: `#F2F2F2`

**レイアウト**:
```
[進捗バー] 画面最上部、細い 3pt のライン（accent色）
  animatableData で問題進行に合わせてアニメーション

[進捗バッジ]「1/5」
  グレー背景（#E0E0E0）/ 角丸 pill / 12pt

[問題カード]
  白背景 / 角丸 16pt / padding 20pt
  問題文: 16pt / lineSpacing 6pt
  ※ タイプライター効果で1文字ずつ表示

[選択肢ボタン × 4]（問題文表示完了後にスライドアップ）
  ┌──────────────────────────────┐
  │ ①  Aさん                   │
  └──────────────────────────────┘
  - 番号バッジ（黒丸 + 白数字）
  - 白背景 / 角丸 16pt
  - 高さ 52pt
```

**タイプライター アニメーション**:
```swift
// Task.sleep を使って1文字ずつ表示
// 間隔: 0.03s / 文字
// 表示中: テキスト末尾に「|」を点滅（0.5s周期）
// 完了後 0.3s → 選択肢をアニメーション表示
```

**選択肢 出現アニメーション**:
```swift
// 各選択肢: offset(y: 40→0) + opacity(0→1)
// stagger: 0.08s ずつ遅延
// spring(response: 0.4, dampingFraction: 0.8)
```

**選択後フィードバック**:
```swift
// 正解選択: 該当ボタン → correctBg + 緑枠 + ✓アイコン
// 不正解選択: 該当ボタン → incorrectBg + 赤枠 + ✗アイコン
//            正解ボタン → correctBg + 緑枠
// Haptics: UINotificationFeedbackGenerator (.success / .error)
// 0.8s後 → 次の問題へ自動遷移
```

---

### 4. ResultView（解説画面）

**背景**: `#F2F2F2`

**レイアウト**:
```
[スコア表示]
  「X / 5」  48pt / セリフ体
  カウントアップアニメーション（0→X, 0.8s, easeOut）
  コメント: スコアに応じた一言

[解説リスト]（ScrollView）
  各問題カード:
  ┌─────────────────────────────┐
  │ Q1  ○ / ×   問題文（省略）   │
  │ ▼                          │
  │ 解説テキスト（DisclosureGroup）│
  └─────────────────────────────┘

[「もう一度」ボタン]
  黒背景 / 白文字 / pill型
  → HomeViewに戻る（NavigationのrootへPop）
```

**スコアコメント**:
```
5問正解: 「完璧です！SPI余裕ですね 🎉」
4問正解: 「あと一歩！惜しかった」
3問正解: 「半分クリア。もう一度挑戦を」
2問以下: 「推論問題、一緒に鍛えましょう」
```

**アニメーション**:
- スコア数字: カウントアップ（Timer or withAnimation）
- 解説カード: staggered フェードイン（0.1s 刻み）

---

## アニメーション共通ルール

| 種類 | duration | easing |
|---|---|---|
| 画面遷移 | 0.35s | easeInOut |
| 要素フェードイン | 0.3s | easeOut |
| ボタンタップ | 0.1s | easeInOut |
| Stagger間隔 | 0.08s | — |
| Spring（選択肢） | response: 0.4, damping: 0.8 | — |

## Haptics
```swift
// 使用箇所
正解時:     UINotificationFeedbackGenerator().notificationOccurred(.success)
不正解時:   UINotificationFeedbackGenerator().notificationOccurred(.error)
ボタンタップ: UIImpactFeedbackGenerator(style: .light).impactOccurred()
```

## アクセシビリティ
- Dynamic Type: 最低限対応（`.minimumScaleFactor(0.8)`）
- VoiceOver: 選択肢ボタンに `.accessibilityLabel` を付与
- 色だけで正誤を伝えない（✓ / ✗ アイコンを併用）
