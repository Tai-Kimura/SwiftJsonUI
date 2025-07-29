# binding_builder - 汎用SwiftJsonUIツール

## 設計原則

### 汎用性の維持
- **binding_builderは汎用的に色々なプロジェクトで使用するツール**
- 絶対パスの指定や特定のプロジェクト名・アプリ名を使わない
- どのiOSプロジェクトでも動作するよう相対パス・動的検索を使用

### アーキテクチャ
- `xcode_project/`ディレクトリ構造（機能別分類）:
  - `generators/` - ファイル生成クラス（ViewGenerator、Base系Generatorなど）
  - `adders/` - Xcodeプロジェクトへの追加クラス
  - `destroyers/` - ファイル削除クラス  
  - `setup/` - 初期設定クラス
  - `pbxproj_manager.rb`, `xcode_project_manager.rb` - 共通管理クラス

### パス設計
- 各クラスで`base_dir = File.expand_path('../..', File.dirname(__FILE__))`でbinding_builderディレクトリを基準点とする
- `ProjectFinder.setup_paths(base_dir, project_file_path)`で動的にパス設定
- 作成対象ディレクトリ：binding_builderと同階層に配置

### 生成ファイル構造
```
プロジェクトルート/
├── YourApp/          (アプリソース)  
├── binding_builder/  (このツール)
├── Core/            (自動生成)
│   ├── Base/        (Base系クラス)
│   └── UI/          (UIViewCreator)
├── View/            (自動生成)
├── Layouts/         (自動生成) 
├── Styles/          (自動生成)
└── Bindings/        (自動生成)
```

### コマンド
- `sjui setup` - ディレクトリ構造とBase系ファイル生成
- `sjui g view <name> [--root]` - ViewController・JSON・Binding生成
- `sjui d view <name>` - View関連ファイル削除
- `sjui build` - バインディングファイル更新

## 注意事項
- 修正時は汎用性を保つこと
- 特定プロジェクトに依存するハードコードを避ける
- パス計算は相対パス・動的検索を使用