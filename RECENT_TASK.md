# DynamicView Component Implementation Task List

## Overview
DynamicViewにsjui_toolsのconverterで対応しているが未実装のコンポーネントを追加する

## Priority Implementation

### 1. Include処理の実装（base_view_converter.rb:61-71の未実装部分）
- [x] **handle_include_and_variables メソッドの実装**
  - [x] includeファイルの読み込み処理
  - [x] shared_data プロパティのサポート
  - [x] data キープロパティのサポート
  - [x] ビルド時のプリプロセッサ処理の実装

## Implementation Checklist

### Basic UI Components
- [x] **Progress** - プログレスバー
  - [x] DynamicProgressView.swift を作成
  - [x] DynamicComponentBuilderに追加
  - [x] テスト用JSONを作成

- [x] **Slider** - スライダー
  - [x] DynamicSliderView.swift を作成
  - [x] DynamicComponentBuilderに追加
  - [x] テスト用JSONを作成

- [x] **Indicator** - インジケーター/ローディング
  - [x] DynamicIndicatorView.swift を作成
  - [x] DynamicComponentBuilderに追加
  - [x] テスト用JSONを作成

### Web & Media
- [ ] **Web/WebView** - Webビュー
  - [ ] DynamicWebView.swift を作成
  - [ ] DynamicComponentBuilderに追加
  - [ ] テスト用JSONを作成

- [ ] **CircleImage** - 円形画像
  - [ ] DynamicImageViews.swift に追加
  - [ ] DynamicComponentBuilderに追加
  - [ ] テスト用JSONを作成

### Selection Components
- [ ] **Radio** - ラジオボタン
  - [ ] DynamicRadioView.swift を作成
  - [ ] DynamicComponentBuilderに追加
  - [ ] テスト用JSONを作成

- [ ] **Segment** - セグメント選択
  - [ ] DynamicSegmentView.swift を作成
  - [ ] DynamicComponentBuilderに追加
  - [ ] テスト用JSONを作成

- [ ] **Toggle/Check/Checkbox** - トグル/チェックボックス
  - [ ] DynamicToggleView.swift を作成
  - [ ] DynamicComponentBuilderに追加
  - [ ] テスト用JSONを作成

### Container Components
- [ ] **TabView** - タブビュー
  - [ ] DynamicTabView.swift を作成
  - [ ] DynamicComponentBuilderに追加
  - [ ] テスト用JSONを作成

- [ ] **GradientView** - グラデーションビュー
  - [ ] DynamicGradientView.swift を作成
  - [ ] DynamicComponentBuilderに追加
  - [ ] テスト用JSONを作成

- [ ] **Blur/BlurView** - ブラービュー
  - [ ] DynamicBlurView.swift を作成
  - [ ] DynamicComponentBuilderに追加
  - [ ] テスト用JSONを作成

- [ ] **SafeAreaView** - セーフエリアビュー
  - [ ] DynamicContainerViews.swift に追加
  - [ ] DynamicComponentBuilderに追加
  - [ ] テスト用JSONを作成

### Advanced Components
- [x] **Include** - 他のレイアウトファイルのインクルード
  - [x] IncludeConverterの実装（sjui_tools側で完了）
  - [x] shared_data プロパティのサポート
  - [x] data キープロパティのサポート
  - [x] リアクティブデータ対応（.id()モディファイア）
  - [x] テスト用JSONを作成

- [ ] **DynamicComponent** - 動的コンポーネント（再帰的な動的ビュー）
  - [ ] DynamicComponentView.swift を作成
  - [ ] DynamicComponentBuilderに追加
  - [ ] テスト用JSONを作成

## Testing Steps
1. 各コンポーネントの実装後、swiftUITestAppで動作確認
2. 動作確認後、メインリポジトリに反映
3. 7.0.0-betaブランチにpush & タグ更新

## Implementation Order (Priority)
1. Toggle/Check/Checkbox (基本的なインタラクション)
2. Progress & Slider (よく使われるUI)
3. Segment & Radio (選択系UI)
4. TabView (ナビゲーション)
5. Indicator (ローディング表示)
6. GradientView & Blur (視覚効果)
7. CircleImage (画像表示拡張)
8. Web/WebView (外部コンテンツ)
9. SafeAreaView (レイアウト)
10. Include & DynamicComponent (高度な機能)

## Notes
- 各コンポーネントはDynamicComponent構造体の既存プロパティを活用
- 必要に応じてDynamicComponent構造体に新しいプロパティを追加
- SwiftUI標準コンポーネントをラップして実装
- viewModelを通じたデータバインディングをサポート