# SwiftJsonUI ツール統合計画

## 概要
binding_builder、hot_loader、swiftui_builderを1つの統合ツールディレクトリにまとめ、統一されたCLIで操作できるようにする。

## 現状の問題点
1. 3つの独立したツールが存在し、それぞれ異なるCLI実装
2. 重複するコードが多い（JSON読み込み、ファイル監視、プロジェクト検索など）
3. 設定ファイルが分散している（config.json、package.json、Gemfile）
4. ユーザーが複数のコマンドを覚える必要がある

## 統合後のディレクトリ構造

```
sjui_tools/
├── bin/
│   └── sjui                    # 統一CLIエントリポイント
├── lib/
│   ├── cli/
│   │   ├── main.rb            # メインCLIクラス
│   │   ├── commands/
│   │   │   ├── init.rb        # プロジェクト初期化
│   │   │   ├── setup.rb       # ライブラリセットアップ
│   │   │   ├── generate.rb    # ファイル生成
│   │   │   ├── build.rb       # ビルド処理
│   │   │   ├── watch.rb       # ファイル監視
│   │   │   ├── hotload.rb     # HotLoaderサーバー
│   │   │   ├── convert.rb     # 変換処理
│   │   │   └── validate.rb    # バリデーション
│   │   └── version.rb
│   ├── core/
│   │   ├── json_loader.rb     # 共通JSON読み込み
│   │   ├── file_watcher.rb    # 共通ファイル監視
│   │   ├── project_finder.rb  # 共通プロジェクト検索
│   │   ├── config_manager.rb  # 共通設定管理
│   │   └── template_engine.rb # 共通テンプレート処理
│   ├── binding/
│   │   ├── binding_generator.rb
│   │   ├── view_creator_generator.rb
│   │   └── handlers/
│   ├── swiftui/
│   │   ├── converter.rb
│   │   ├── converter_factory.rb
│   │   └── views/
│   └── hotloader/
│       ├── server.rb          # Ruby版サーバー実装
│       ├── websocket.rb
│       ├── layout_loader.js   # クライアント用JS
│       └── client.js          # クライアント用JS
├── config/
│   ├── default.json
│   └── library_versions.json
├── Gemfile
├── package.json               # HotLoader用Node依存（オプション）
├── README.md
└── VERSION
```

## 統一CLIコマンド体系

```bash
# 初期化
sjui init [--mode=all|binding|swiftui]

# セットアップ
sjui setup [--platform=ios]

# 生成コマンド
sjui generate view <name> [--mode=binding|swiftui|dynamic]
sjui generate partial <name>
sjui generate collection <folder/name>
sjui generate binding <name>

# 短縮形
sjui g view <name>
sjui g partial <name>
sjui g collection <folder/name>

# ビルド・変換
sjui build [--mode=binding|swiftui|all]
sjui convert <input> <output> [--from=json --to=swiftui]

# 開発ツール
sjui watch [--mode=binding|swiftui|all]
sjui hotload [--port=8080]
sjui server [--port=8080]  # hotloadのエイリアス

# バリデーション
sjui validate [files...]

# その他
sjui version
sjui help [command]
```

## 実装フェーズ

### Phase 1: 基盤整備（1-2週間）
1. sjui_toolsディレクトリ作成
2. 共通ライブラリ（core/）の実装
   - JSONローダーの統一
   - ファイル監視の統一
   - プロジェクト検索の統一
   - 設定管理の統一
3. 統一CLIフレームワークの実装

### Phase 2: 既存機能の移植（2-3週間）
1. binding_builderの機能を移植
   - ジェネレーター類
   - ハンドラー類
   - Xcodeプロジェクト操作
2. swiftui_builderの機能を移植
   - コンバーター類
   - ビュー生成ロジック
3. hot_loaderの機能を移植
   - Ruby版サーバー実装
   - WebSocket通信

### Phase 3: 統合とテスト（1週間）
1. 全機能の統合テスト
2. 既存プロジェクトでの動作確認
3. 移行スクリプトの作成
4. ドキュメント作成

### Phase 4: 移行支援（1週間）
1. 既存ツールから新ツールへの移行ガイド
2. 後方互換性の確保（エイリアスコマンド）
3. 段階的廃止計画

## 技術的な統合ポイント

### 1. 共通化できるコード
- JSON読み込み・解析ロジック
- ファイル監視メカニズム
- テンプレート処理
- プロジェクトファイル検索
- 設定ファイル管理
- エラーハンドリング
- ログ出力

### 2. モード切り替えの実装
```ruby
class ConfigManager
  def mode
    @config['mode'] || detect_mode_from_project
  end
  
  def detect_mode_from_project
    # プロジェクト構造から自動判定
    if File.exist?('Package.swift')
      'swiftui'
    else
      'binding'
    end
  end
end
```

### 3. プラグイン構造
```ruby
module SjuiTools
  class Plugin
    def self.register(name, klass)
      @plugins ||= {}
      @plugins[name] = klass
    end
    
    def self.load(name)
      @plugins[name]
    end
  end
end
```

## 移行戦略

### 1. 既存ツールのラッパー作成
```bash
# 移行期間中の互換性確保
binding_builder/sjui -> ../sjui_tools/bin/sjui binding
swiftui_builder/bin/sjui-swiftui -> ../sjui_tools/bin/sjui swiftui
```

### 2. 設定ファイルの自動変換
```ruby
# 既存のconfig.jsonを新形式に変換
class ConfigMigrator
  def migrate_binding_config(old_config)
    {
      'mode' => 'binding',
      'binding' => old_config
    }
  end
end
```

### 3. 段階的な機能追加
- v1.0: 基本的な統合（既存機能の移植）
- v1.1: 新機能追加（拡張機能など）
- v1.2: パフォーマンス改善
- v2.0: 既存ツールの廃止

## 期待される効果

1. **開発効率の向上**
   - 1つのコマンドですべての操作が可能
   - 共通化によるバグの削減
   - メンテナンスコストの削減

2. **ユーザビリティの向上**
   - 統一されたインターフェース
   - より直感的なコマンド体系
   - 包括的なヘルプシステム

3. **拡張性の向上**
   - プラグインシステムによる機能追加
   - 新しいプラットフォームへの対応が容易
   - コミュニティによる拡張が可能

## リスクと対策

1. **既存ユーザーへの影響**
   - 対策: 十分な移行期間と互換性の確保

2. **複雑性の増加**
   - 対策: モジュール設計による複雑性の分離

3. **テスト負荷**
   - 対策: 段階的な移行と自動テストの充実

## 次のステップ

1. この計画のレビューと承認
2. Phase 1の詳細設計
3. プロトタイプの作成
4. フィードバックの収集
5. 本実装の開始