# TODO for Version 7.0.0-alpha

## 概要
このファイルはバージョン7.0.0-alphaで実装予定の機能・タスクを記録するためのものです。

## 実装済み機能

### SwiftJsonUIのJSON形式からSwiftUIのViewコンポーネントを自動生成する機能
- [x] 基本的なコンバーターの実装完了
  - [x] JSONパーサーの実装
  - [x] SwiftUIコード生成器の実装
  - [x] 各UIコンポーネントのマッピング定義
  - [x] テンプレート変数（@{}）のサポート

### 実装内容の詳細

#### 1. ディレクトリ構造
```
swiftui_builder/
├── json_to_swiftui_converter.rb  # メインコンバーター
├── converter_factory.rb           # コンバーターファクトリー
└── views/                        # 各コンポーネントのコンバーター
    ├── base_view_converter.rb    # 基底クラス
    ├── template_helper.rb        # テンプレート変数処理
    ├── label_converter.rb        # Label → Text
    ├── button_converter.rb       # Button → Button
    ├── view_converter.rb         # View/SafeAreaView
    ├── textfield_converter.rb    # TextField
    ├── image_converter.rb        # Image
    ├── scrollview_converter.rb   # ScrollView
    ├── table_converter.rb        # Table → List
    └── ... （その他多数のコンバーター）
```

#### 2. サポートされているコンポーネント
- **基本コンポーネント**: Label, Button, TextField, TextView, Image, Switch, Check, Radio
- **コンテナ**: View, SafeAreaView, Scroll, GradientView, Blur
- **リスト**: Table, Collection
- **その他**: Segment, Progress, Slider, Indicator, Web, NetworkImage など

#### 3. 主な機能
- SwiftJsonUIの正しい属性名を使用（fontSize, fontColor など）
- テンプレート変数（@{variable_name}）の自動処理
- 型推論（String, CGFloat, Color, Bool）
- @Stateプロパティの自動生成
- プレビュー用サンプルデータの生成
- weight属性のサポート（flexible layout）
- 個別のpadding/margin属性のサポート

#### 4. 使用例
```bash
# 単一ファイルの変換
ruby swiftui_builder/json_to_swiftui_converter.rb input.json output.swift

# お知らせ画面の例
ruby swiftui_builder/json_to_swiftui_converter.rb test/notification_list.json
ruby swiftui_builder/json_to_swiftui_converter.rb test/notification_cell.json
```

#### 5. 最新のアップデート（2025-08-02）
- **横スクロールのサポート**: ScrollViewコンバーターに`orientation`属性を追加
- **Collection/Tableのセルレイアウトサポート**: 
  - `cell_layout`属性で指定されたセルビューを使用
  - `binding.data`でデータ配列をバインディング
  - データ配列の型推論（`[NotificationItem]`など）
- **コンバーターファクトリーの修正**: ScrollView/Textなどのマッピングを追加
- **プレビューデータの改善**: 配列型のプロパティに空配列を使用

#### 6. テストファイル
- `test/お知らせ.png` - 参考デザイン画像
- `test/notification_list.json` - TableViewを使用したリスト実装
- `test/notification_cell.json` - セルレイアウト（テンプレート変数付き）
- `test/notification_with_data.json` - データバインディングの例
- `test/NotificationCompleteView.swift` - 完全な実装例
- `test/table_test.json` - Tableのセルレイアウトテスト
- `test/list_components_test.json` - CollectionとTableの統合テスト

## 今後の課題

### 機能追加
- [x] typeキーでSwiftJsonUIとSwiftUI両方のコンポーネント名に対応（実装済み）
  - "type": "Label" (SwiftJsonUI) → Text (SwiftUI)
  - "type": "Scroll" (SwiftJsonUI) → ScrollView (SwiftUI)
  - 現在の実装: ConverterFactoryで両方の名前を受け入れ、適切なSwiftUIコンポーネントに変換
- [ ] コマンドラインツールの作成（sjui コマンドへの統合）
- [ ] 画像からJSONへの自動変換機能
- [ ] より複雑な条件式のサポート（@{icon_type == 'emoji' ? 30 : 12}）
- [ ] includeファイルのサポート
- [ ] スタイルファイルのサポート

### 改善点
- [ ] エラーハンドリングの強化
- [ ] 生成コードの最適化（不要なframeモディファイアの削除など）
- [ ] ドキュメントの作成

## メモ
- 作成日: 2025-08-02
- ブランチ: 7.0.0-alpha
- 主な成果: SwiftJsonUIのJSON形式からSwiftUIへの自動変換が可能になった