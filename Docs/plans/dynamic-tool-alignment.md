# Dynamic モード ⇄ sjui_tools 整合計画

## 目的

sjui_tools（`/Users/like-a-rolling_stone/resource/jsonui-cli/sjui_tools/`）が出力・仕様として宣言する属性と、SwiftJsonUI ライブラリの Dynamic ランタイム（`Sources/SwiftJsonUI/Classes/SwiftUI/Dynamic/`）が実際に解釈する属性のズレを洗い出し、**tool を正**として Dynamic 側で埋める。

## 照合対象

| 側 | パス |
|---|---|
| tool（正） | `jsonui-cli/sjui_tools/lib/core/attribute_definitions.json` |
|  | `jsonui-cli/sjui_tools/lib/swiftui/converters/*.rb` |
| lib | `SwiftJsonUI/Sources/SwiftJsonUI/Classes/SwiftUI/Dynamic/DynamicComponent.swift` |
|  | `.../Dynamic/DynamicComponentBuilder.swift` |
|  | `.../Dynamic/Converters/*.swift` |
|  | `.../Dynamic/DynamicModifierHelper.swift` / `DynamicHelpers.swift` / `DynamicBindingHelper.swift` / `DynamicDecodingHelper.swift` |

## 方針

1. **ランタイムは tool の出力 JSON をそのまま解釈できること**を保証する。
2. tool が **SwiftUI 制約でコメントアウトしている属性**（`placeholderColor` 等）は Dynamic 側でも「noop＋警告」に揃える。
3. tool 側が未出力でライブラリ側だけが持つ属性（`loadingImage` 等）は `attribute_definitions.json` に追加して tool に逆輸入する（別計画、本書は lib 側が対象）。
4. 名前ゆれ（`minimumValue` vs `minimum`）は **tool が出す形を lib が全部受ける**。lib 側の生の名前は互換維持で残す。

---

## Phase 0: 共通ヘルパー

### 0-1. DynamicDecodingHelper / DynamicBindingHelper

| 課題 | 現状 | 対応 |
|---|---|---|
| 名前ゆれ吸収が個別 Converter に散在 | SliderConverter 内で `component.minimumValue ?? rawData["minimum"]` | `DynamicDecodingHelper.firstNonNil(_:_:_:)` を追加して統一 |
| `enabled` の型混在 | Bool と `@{binding}` String が別経路 | `resolveBoolOrBinding(from:data:)` を 1 本化して Button/TextField/Toggle/Collection で共通化 |
| `visibility` と `hidden` の優先順位 | 両方あり、Converter ごとに扱いが微妙に違う | `resolveVisibility(component:data:)` を 1 本化（`hidden==true` 優先、次に `visibility`） |

### 0-2. テーマ対応カラー解決（最重要）

tool の `ColorManager`（`sjui_tools/lib/core/resources/color_manager.rb`）は **多テーマ（light/dark/custom）**を出力するが、Dynamic 側は `SwiftJsonUIConfiguration` のグローバル変数経由しかない。

| 対応 | 内容 |
|---|---|
| `DynamicDecodingHelper.resolveColor(key:)` を新設 | tool の `colors.json` スキーマ（`modes`, `fallback_mode`, `systemModeMapping`）を JSON ランタイムでも読む |
| `SwiftJsonUIConfiguration.currentThemeMode` を `ObservableObject` で公開 | Dynamic ビューが再コンポーズされる |
| Converter 全般 | `fontColor` / `background` / `borderColor` / `tintColor` / `highlightColor` 等、色が入る全属性は `resolveColor` 経由 |

参考: v9.1.0 で `ColorProvider` が `ObservableObject` 化済み（SwiftJsonUI 82ec4d9）。Dynamic 側から参照するフックが未結線。

---

## Phase 1: コンポーネント別ギャップ

> **凡例**  
> 🔴 = tool が出すのに lib が解釈しない（Dynamic で壊れる）  
> 🟡 = tool が出さないが lib にだけある（将来的に tool に足す）  
> 🟢 = 名前ゆれ（互換レイヤ追加で済む）

### 1-1. Label / Text（`DynamicTextConverter.swift`）

| 属性 | 状態 | 対応 |
|---|---|---|
| `fontStyle` | 🔴 | `italic` を `.italic()` にマップ。`normal` は無処理 |
| `hintAttributes` / `hintColor` / `hintFont` / `hintFontSize` | 🟡→deprecate | Label には placeholder がないので **ランタイムで読み捨て**、警告ログのみ。tool 側のコメント文言と合わせる |
| `textShadow` | 🟡 | `DynamicShadow` を text 用に派生（Text の `.shadow` は無いので overlay 実装。P2） |
| `edgeInset` | 🟡 | `.padding` と統合（`paddings` が無いときのみ適用） |

### 1-2. Button（`DynamicButtonConverter.swift`）

| 属性 | 状態 | 対応 |
|---|---|---|
| `confirmationDialog` | 🔴 | `String`（title）または Object（`{title, message, confirmText, cancelText}`）を受け、`.confirmationDialog` modifier を生やす |
| `style` | 🔴 | `"plain"|"bordered"|"borderedProminent"|"borderless"` を `.buttonStyle(...)` に。`nil` は既存スタイル |
| `highlightBackground` / `tapBackground` / `disabledBackground` | 🟢 | 既に lib は対応済み。tool 出力の 3 属性すべてを `StateAwareButtonView` に確実に流す（経路漏れチェック） |

### 1-3. TextField（`DynamicTextFieldConverter.swift` / `FocusableTextField.swift`）

| 属性 | 状態 | 対応 |
|---|---|---|
| `nextFocus` | 🔴 | `component.nextFocus` を `FocusableTextField` にそのまま渡す（現状は Swift コード生成時しか機能しない）。tool 出力の id を FocusChain コンテキストで解決 |
| `contentType` | 🔴 | `UITextContentType` 文字列 → `.textContentType(.emailAddress)` 等にマップ |
| `textPaddingLeft` | 🔴 | `.padding(.leading, value)` を追加 |
| `placeholderColor` / `hintColor` / `hintFont` / `hintFontSize` | 🟡→deprecate | SwiftUI では Text placeholder のスタイル不可。ランタイムでも警告ログ、値は保持だけ |

### 1-4. Image / NetworkImage（`DynamicImageConverter.swift`）

| 属性 | 状態 | 対応 |
|---|---|---|
| `loadingImage` / `errorImage` / `highlightSrc` | 🟡 | lib に既に AsyncImage ステートがある。tool 側には無いが **ランタイムは引き続きサポート**（rawData 経由で読む） |
| `canTap` | 🟡 | lib 専用。`onClick` があれば自動で tap 可能にする現状ロジックを維持、`canTap:false` で明示的に無効化できる経路を残す |
| `systemIcon` | 🟡 | lib 専用。tool 出力には無いが rawData から拾う |

### 1-5. Collection（`DynamicCollectionConverter.swift`）

| 属性 | 状態 | 対応 |
|---|---|---|
| `lazy: false` | ✓ 整合済み（v9.0.1） | 回帰テスト追加（eager 描画時の Spacer 計算が parent scrollView 有無で変わるケース） |
| `onItemAppear` | 🔴 | `ForEach` の各要素に `.onAppear { eventHandlers["onItemAppear"]?(item) }` を付与 |
| `onPageChanged` | 🔴 | paging + `TabView(selection:)` でのみ発火。`selectedIndex` 経由で `onChange` をフック |
| `cellWidth` / `cellHeight` | 🔴 | Grid レイアウトに `GridItem(.fixed(cellWidth))` を適用。現状は cell 自身の frame 頼りで tool 仕様と不一致 |
| `cellIdProperty` | 🔴 | `ForEach(items, id: \.<path>)` の keyPath として利用。未指定時は `\.self` |
| `hideSeparator` | 🔴 | `.listRowSeparator(.hidden)` を List 使用時のみ |
| `selectedTabIndex` / `currentPage` | 🟢 | `selectedIndex` のエイリアスとして rawData から受ける |

### 1-6. ScrollView（`DynamicScrollViewConverter.swift`）

| 属性 | 状態 | 対応 |
|---|---|---|
| `scrollMode` | 🟡→除外 | Web 専用属性。Dynamic では明示的に **無視（警告なし）**。`attribute_definitions.json` の platform フラグで tool 側が SwiftUI 出力しないように別計画で対処 |
| `scrollAnimated` | 🔴 | `scrollTo` と併用。`withAnimation { proxy.scrollTo(id, anchor:) }` にするかを判定 |

### 1-7. Slider（`DynamicSliderConverter.swift`）

| 属性 | 状態 | 対応 |
|---|---|---|
| `minimumValue` / `maximumValue` | 🟢 | `minimum` / `maximum` と両受け。Phase 0-1 の `firstNonNil` に差し替え |
| `minValue` / `maxValue` | 🟢 | 同上 |
| `progressTintColor` / `trackTintColor` | 🟡→deprecate | SwiftUI Slider は unified tint のみ。`tintColor` に寄せてログ |

### 1-8. Toggle / Switch / Checkbox / Radio

| 属性 | 状態 | 対応 |
|---|---|---|
| `toggleStyle` | 🔴 | `"switch"|"button"|"automatic"` を `.toggleStyle(...)` に |
| `trackTintColor` / `onTintColor` | 🟡→deprecate | `tintColor` に寄せる |
| `checkedColor` / `uncheckedColor` / `icon` / `selectedIcon` / `iconSize` / `iconColor` | 🟡 | lib 側に既に全部ある。tool 側で未公開。rawData 経由で読むロジックは維持 |

### 1-9. Segment（`DynamicSegmentConverter.swift`）

| 属性 | 状態 | 対応 |
|---|---|---|
| `style` | 🔴 | segmented picker は style 指定が効かない。tool 出力は読み捨て＋ログ |
| `normalColor` / `selectedColor` | 🟡 | lib 側にあり tool に無い。rawData から読む現状維持 |

### 1-10. GradientView / Blur（`DynamicGradientConverter.swift` / `DynamicBlurConverter.swift`）

| 属性 | 状態 | 対応 |
|---|---|---|
| `gradient`（オブジェクト） | 🔴 | tool は `{ colors: [...], locations: [...], startPoint, endPoint }` を出す。lib は `colors` プロパティを直接期待。`gradient` オブジェクトをデコードして展開するブリッジを追加 |
| `gradientDirection` | 🔴 | `"topToBottom"|"leftToRight"|...` を `startPoint/endPoint` にマップ（`startPoint/endPoint` 未指定時のみ） |
| `color`（Blur） | 🔴 | `UIBlurEffect.Style` 文字列（`"light"|"dark"|"prominent"`）→ `.material(...)` にマップ |

### 1-11. Web / WebView

| 属性 | 状態 | 対応 |
|---|---|---|
| `url` | 🔴 | lib は `html` のみサポート。`url` 指定時は `URLRequest` ベースで WKWebView を初期化 |

### 1-12. View / Container（`DynamicViewConverter.swift`）

| 属性 | 状態 | 対応 |
|---|---|---|
| `gravity`（配列 / pipe 区切り） | ✓ | 既に `alignment` に変換している。tool が `"top|left"` の文字列形式で出す場合の parse を確認（テスト追加） |
| `indexBelow` / `indexAbove` | ✓ | `.zIndex` で対応済み。回帰テスト |

### 1-13. TabView（`DynamicTabViewConverter.swift`）

| 属性 | 状態 | 対応 |
|---|---|---|
| `selectedTabIndex` | 🟢 | `selectedIndex` のエイリアス |
| `onPageChanged` | 🟢 | `onTabChange` のエイリアス |

---

## Phase 2: クロスカッティング属性

| 属性 | 状態 | 対応 |
|---|---|---|
| `onLongPress` | 🟡 | `DynamicModifierHelper.applyGestures` 経由で lib 側は対応済み。tool 出力には未定義 → tool 側で追加するまでは rawData から読む経路を維持 |
| `minTopMargin` / `maxTopMargin` 等（12 variants） | 🟡 | lib 専用制約。tool 側に `attribute_definitions.json` 追加を別計画で |
| `widthRaw` / `heightRaw` / `idealWidth` / `idealHeight` | 🟡 | lib デバッグ用・SwiftUI 固有。tool 側では不要 |
| `alignTopView` / `alignBottomView` ...（6 variants） | 🟢 | `alignTopOfView` 系のエイリアスとして両方受ける |

---

## Phase 3: テーマ / カラー刷新（Phase 0-2 の実装本体）

| 対応 | 内容 |
|---|---|
| `DynamicColorResolver` を新設 | `Resources/Colors/colors.json` のテーマ配列を解釈。`currentThemeMode` と `systemModeMapping` でキー解決 |
| `DynamicComponent.fontColor` 等を `AnyCodable` で受ける | 直値（`"#RRGGBB"`）とシンボル（`"primary"`）を両方受ける |
| `SwiftJsonUIConfiguration.themePublisher` | `ObservableObject`。DynamicView が `@ObservedObject` で受けて再コンポーズ |
| 回帰テスト | light/dark 切替で背景・文字色・ボーダーが追従する snapshot テスト |

---

## Phase 4: `attribute_definitions.json` 逆輸入（tool 側別計画）

lib にはあるが tool にない属性を tool に足す作業は、**jsonui-cli 側の別計画**に切り出した:

→ `/Users/like-a-rolling_stone/resource/jsonui-cli/docs/plans/attribute-definitions-backfill.md`

本計画 Phase 1 / Phase 2 の 🟡 マーク属性が backfill 対象。逆輸入計画の Phase 2〜3 が完了したら、本計画で rawData 経由に回避していた属性を canonical 名で受け直す。

---

## 実装順序

1. **Phase 0**（ヘルパー刷新・テーマ解決フック）
2. **Phase 1-5** Collection（利用頻度最大）
3. **Phase 1-2, 1-3**（Button / TextField; UX 影響大）
4. **Phase 1-10** GradientView / Blur（描画崩れが目立つ）
5. **Phase 1 残り**
6. **Phase 2**
7. **Phase 3** テーマ実装本体（Phase 0 のフックを本実装に置換）
8. **Phase 4** は jsonui-cli 側の issue として切り出し

## 受け入れ基準

- [ ] Dynamic モードのサンプルアプリで tool 生成 JSON をそのまま描画し、静的生成 SwiftUI コードとピクセル差分なし（snapshot）
- [ ] `SwiftJsonUITests` に Dynamic ↔ tool JSON 互換テスト（各 Converter 1 ケース以上）を追加
- [ ] `placeholderColor` など deprecate 対象は実行時に 1 回だけ警告ログ
- [ ] 多テーマ対応サンプル画面が light/dark 切替で即時再描画
