# pbxprojファイル安全編集ガイドライン

## 🚨 重要な安全規則

**pbxprojファイルを編集するすべての処理は、以下の安全措置を必須とする**

### 1. 必須の安全フロー

```ruby
def safe_pbxproj_edit_example
  return unless File.exist?(@project_file_path)
  
  # 1. バックアップ作成
  backup_path = create_backup(@project_file_path)
  
  begin
    # 2. ファイル読み込み
    content = File.read(@project_file_path)
    
    # 3. 編集処理
    # ... 編集ロジック ...
    
    # 4. ファイル書き込み
    File.write(@project_file_path, content)
    
    # 5. 整合性検証
    if validate_pbxproj(@project_file_path)
      puts "✅ pbxproj file validation passed"
      cleanup_backup(backup_path)
    else
      puts "❌ pbxproj file validation failed, rolling back..."
      FileUtils.copy(backup_path, @project_file_path)
      cleanup_backup(backup_path)
      raise "pbxproj file corruption detected"
    end
    
  rescue => e
    puts "Error during pbxproj edit: #{e.message}"
    if File.exist?(backup_path)
      FileUtils.copy(backup_path, @project_file_path)
      cleanup_backup(backup_path)
      puts "Restored pbxproj file from backup"
    end
    raise e
  end
end
```

### 2. 必須メソッド

以下のメソッドがPbxprojManagerクラスに実装済み：

- `create_backup(file_path)` - タイムスタンプ付きバックアップ作成
- `cleanup_backup(backup_path)` - バックアップファイル削除
- `validate_pbxproj(file_path)` - plutilによる構文検証
- `basic_pbxproj_validation(file_path)` - フォールバック検証

### 3. 対象となる編集処理

以下の処理は**必ず**安全フローを適用すること：

- ✅ `setup_membership_exceptions` - 既に適用済み
- ✅ `add_swiftjsonui_package_to_pbxproj` - 適用済み
- ✅ HotLoad Build Phase追加 - 適用済み
- ✅ ファイル・グループ追加 - 適用済み
- ✅ プロジェクトエントリ削除 - 適用済み
- ✅ ViewControllerAdder - 独自の安全機構あり
- ✅ BindingFilesAdder - 独自の安全機構あり

### 4. エラー処理

#### 検証失敗時
- 自動的にバックアップから復元
- エラーメッセージ出力
- 例外を再発生させて処理停止

#### 例外発生時
- try-catch-finallyパターンで確実にロールバック
- バックアップファイルのクリーンアップ
- 元のエラー情報を保持

### 5. ベストプラクティス

#### DO（すべきこと）
- 編集前に必ずバックアップ
- 編集後に必ず検証
- エラー時は必ずロールバック
- バックアップファイルのクリーンアップ

#### DON'T（してはいけないこと）
- バックアップなしでの直接編集
- 検証なしでの処理完了
- エラー時の放置
- バックアップファイルの残存

### 6. 実装チェックリスト

新しいpbxproj編集処理を追加する際は以下を確認：

- [ ] `create_backup`でバックアップ作成
- [ ] `begin-rescue-end`でエラーハンドリング
- [ ] `File.write`後に`validate_pbxproj`実行
- [ ] 検証成功時に`cleanup_backup`実行
- [ ] 検証失敗時にロールバック処理
- [ ] 例外発生時にロールバック処理

### 7. 注意事項

- pbxprojファイルはXcodeプロジェクトの心臓部
- 破損すると開発不可能になる
- gitによる復元は最後の手段
- 予防が最も重要

## 例：既存コードの修正が必要な箇所

### 適用完了済みのファイル

- ✅ **DirectorySetup.rb** - `add_swiftjsonui_package_to_pbxproj`メソッド
- ✅ **HotloadSetup.rb** - Build Phase追加処理
- ✅ **XcodeProjectManager.rb** - ファイル・グループ追加処理
- ✅ **Destroyer.rb** - プロジェクトエントリ削除処理
- ✅ **ViewControllerAdder.rb** - 独自バックアップ機構
- ✅ **BindingFilesAdder.rb** - 独自バックアップ機構

---

**このガイドラインは必須事項です。pbxproj編集処理を追加・修正する際は必ず従ってください。**