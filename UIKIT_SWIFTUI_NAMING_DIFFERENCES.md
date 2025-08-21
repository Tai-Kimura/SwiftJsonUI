# UIKit vs SwiftUI - 名前の違い

## ビュータイプの名前の違い

### 同じ役割で名前が異なるもの

| 役割 | UIKit | SwiftUI | 備考 |
|------|-------|---------|------|
| テキスト表示 | `Label` | `Text` / `Label` | SwiftUIは`Text`が主流、`Label`も受け付ける |
| スクロールビュー | `Scroll` | `ScrollView` / `Scroll` | 両方受け付けるが正式名が異なる |
| ぼかし効果 | `Blur` | `BlurView` / `Blur` | 両方受け付ける |
| トグルスイッチ | `Switch` | `Toggle` / `Switch` | SwiftUIは`Toggle`が正式 |
| チェックボックス | `Check` | `Checkbox` / `Check` | SwiftUIは`Checkbox`も受け付ける |
| Webビュー | `Web` | `WebView` / `Web` | 両方受け付ける |

### UIKitのみのビュータイプ
- `CircleView` - 円形ビュー（SwiftUIではViewのモディファイアで実現）
- `CircleImage` - 円形画像（SwiftUIではImageのモディファイアで実現）

### SwiftUIのみのビュータイプ  
- `TabView` - タブビュー
- `DynamicComponent` - 動的コンポーネント
- `Include` - レイアウトのインクルード機能

## 属性名の違い

### 共通属性で名前が異なるもの

| 役割 | UIKit | SwiftUI | 説明 |
|------|-------|---------|------|
| 透明度 | `alpha` | `opacity` / `alpha` | SwiftUIは両方受け付ける |
| プレースホルダー | `hint` | `hint` / `placeholder` | TextFieldのプレースホルダー（SwiftUIは両方受け付ける） |
| プレースホルダー色 | `hintColor` | `hintColor` / `placeholderColor` | プレースホルダーの色 |
| ハイライト色 | `highlightColor` | `highlightColor` | ボタンなどのハイライト時の色（`hilightColor`はスペルミスなので使用しない） |
| 行数 | `lines` | `lineLimit` | テキストの最大行数 |
| 自動縮小 | `autoShrink` | `minimumScaleFactor`と併用 | テキストの自動縮小 |
| セキュアテキスト | `secure` | `isSecure` | パスワード入力 |

### イベントハンドラーの名前の違い

| UIKit | SwiftUI | 説明 |
|-------|---------|------|
| `onclick` | `onclick` | 同じだが、SwiftUIではactionとも呼ばれる |
| `onValueChange` | `onValueChanged` | スイッチなどの値変更 |
| `onTextChange` | `onTextChanged` / `onEditingChanged` | テキスト変更イベント |

### レイアウト関連の違い

| 役割 | UIKit | SwiftUI | 説明 |
|------|-------|---------|------|
| 方向 | `orientation` | `orientation` | 同じ（vertical/horizontal） |
| スタック方向 | `direction` | `distribution` | スタックの配置方向 |
| 内側の余白 | （各エッジ個別指定） | `padding` | SwiftUIは配列でも指定可能 |
| 外側の余白 | `topMargin`等 | `margin` | SwiftUIは配列でも指定可能 |
| コンテンツモード | `contentMode` | `contentMode` / `resizable` | 画像の表示方法 |

### UIKit特有の属性
- `compressHorizontal` / `compressVertical` - コンテンツ圧縮優先度
- `hugHorizontal` / `hugVertical` - コンテンツハギング優先度
- `userInteractionEnabled` - ユーザー操作の有効/無効
- `canTap` - タップ可能かどうか

### SwiftUI特有の属性
- `visibleIf` - 条件付き表示
- `role` - ボタンの役割（destructive, cancel）
- `progressViewStyle` - プログレスビューのスタイル
- `textFieldStyle` - テキストフィールドのスタイル
- `buttonStyle` - ボタンのスタイル
- `zIndex` - Z軸の順序
- `rotationAngle` - 回転角度
- `scaleX` / `scaleY` - スケール変換

## バインディング記法の違い

両モードとも `@{propertyName}` 形式でバインディングをサポートしていますが：

- **UIKit**: バインディングハンドラーを通じて手動で値を更新
- **SwiftUI**: `@State`, `@Binding`, `@ObservedObject`と自動的に統合

## 注意点

1. **SwiftUIモード**では、UIKitの名前も多くの場合受け付けるように設計されている（例：`Label`→`Text`に自動変換）
2. **UIKitモード**は、より細かいレイアウト制御が可能（constraint系の属性）
3. **SwiftUIモード**は、よりモダンなスタイルシステムを持つ（`buttonStyle`, `textFieldStyle`など）