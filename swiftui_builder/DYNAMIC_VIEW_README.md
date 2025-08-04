# SwiftUI Dynamic View System

SwiftJsonUIのSwiftUI版動的ビュー生成システムです。DEBUGビルドではHotLoaderによるリアルタイム更新、リリースビルドではバンドルされたJSONからのビュー生成をサポートします。

## 特徴

- 🔥 **HotLoader対応**: DEBUGビルドでJSONファイルの変更を即座に反映
- 📦 **リリース最適化**: リリースビルドではバンドルされたJSONを使用
- 🎨 **完全なSwiftJsonUI互換**: 既存のJSON形式をそのまま使用可能
- 🚀 **パフォーマンス**: 条件付きコンパイルで最適なパフォーマンスを実現

## セットアップ

### 1. Info.plistの設定

```xml
<key>CurrentIp</key>
<string>localhost</string>
<key>HotLoader Port</key>
<string>8080</string>
```

### 2. HotLoaderサーバーの起動

SwiftJsonUIのHotLoaderサーバーをそのまま使用できます：

```bash
cd path/to/json/files
sjui server
```

## 使用方法

### 基本的な使い方

```swift
import SwiftUI
import SwiftJsonUI

struct MyView: View {
    var body: some View {
        DynamicView(jsonName: "my_layout")
            .onAppear {
                #if DEBUG
                HotLoader.instance.isHotLoadEnabled = true
                #endif
            }
    }
}
```

### JSONファイルの配置

#### DEBUGビルド
- HotLoaderサーバーのディレクトリにJSONファイルを配置
- ファイルを編集すると自動的にアプリに反映

#### リリースビルド
- XcodeプロジェクトにJSONファイルを追加
- Build PhasesでCopy Bundle Resourcesに含まれることを確認

### サポートされているコンポーネント

- **基本コンポーネント**: View, Text, Button, Image, TextField
- **高度なコンポーネント**: TextView, SelectBox, IconLabel, NetworkImage
- **レイアウト**: ScrollView, Collection, Table
- **その他**: Switch, Slider, Progress

### JSONフォーマット例

```json
{
  "type": "View",
  "width": "matchParent",
  "height": "matchParent",
  "padding": [20],
  "child": [
    {
      "type": "Text",
      "text": "Hello, SwiftUI!",
      "fontSize": 24,
      "fontColor": "#000000"
    },
    {
      "type": "TextField",
      "id": "nameField",
      "hint": "Enter your name",
      "margin": [10, 0]
    },
    {
      "type": "Button",
      "text": "Submit",
      "background": "#007AFF",
      "fontColor": "#FFFFFF",
      "cornerRadius": 8,
      "padding": [10, 20],
      "action": "submit"
    }
  ]
}
```

## 条件付きコンパイル

```swift
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            // DEBUGビルド: HotLoaderを使用
            ContentView()
                .onAppear {
                    print("Running in DEBUG mode with HotLoader")
                }
            #else
            // リリースビルド: 最適化されたビュー
            ContentView()
            #endif
        }
    }
}
```

## パフォーマンスの考慮事項

### DEBUGビルド
- HotLoaderによるWebSocket通信
- ファイル変更の監視
- 動的なJSON解析とビュー生成

### リリースビルド
- バンドルされたJSONの使用
- WebSocket通信なし
- 初回読み込み時のみJSON解析

## トラブルシューティング

### HotLoaderが動作しない
1. Info.plistの設定を確認
2. HotLoaderサーバーが起動しているか確認
3. ファイアウォール設定を確認

### JSONが読み込まれない
1. JSONファイルがBundle Resourcesに含まれているか確認
2. ファイル名の大文字小文字を確認
3. JSON形式が正しいか確認

## 既存のSwiftJsonUIプロジェクトからの移行

1. 既存のJSONファイルはそのまま使用可能
2. UIKitベースのコードをSwiftUIのDynamicViewに置き換え
3. HotLoaderサーバーは既存のものをそのまま使用

## 制限事項

- カスタムアクションハンドラーは別途実装が必要
- 一部の高度なアニメーションは未サポート
- パフォーマンスは事前コンパイルされたビューには劣る

## まとめ

SwiftUI Dynamic View Systemを使用することで、SwiftJsonUIの利便性をSwiftUIでも享受できます。開発時はHotLoaderでの即座の反映、リリース時は最適化されたパフォーマンスを実現します。