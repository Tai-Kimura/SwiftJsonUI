# SwiftJsonUI Tools - 重要な実装ガイドライン

## JSON互換性について

**重要**: SwiftJsonUIとSwiftUIは同じJSONファイルで両対応する必要があります。

### 基本原則

1. **JSONのキー名は必ずSwiftJsonUIの仕様に従う**
   - SwiftJsonUIで定義されているキー名をそのまま使用する
   - SwiftUI独自のキー名を勝手に追加しない
   - 同じJSONファイルがSwiftJsonUIでもSwiftUIでも動作することが前提

2. **属性名の例**
   - `text` - テキスト内容
   - `fontSize` - フォントサイズ  
   - `fontColor` - フォントカラー
   - `background` - 背景色
   - `cornerRadius` - 角の丸み
   - `padding` / `paddings` - パディング
   - `onclick` - クリックアクション（onClickではない）
   - `hint` - プレースホルダー（placeholderではない）
   - `edgeInset` - エッジインセット
   - `containerInset` - コンテナインセット

3. **コンポーネントタイプ**
   - `Label` / `Text` - テキスト表示
   - `Button` - ボタン
   - `TextField` - テキスト入力
   - `TextView` - 複数行テキスト入力
   - `Image` - 画像
   - `View` / `SafeAreaView` - コンテナビュー
   - `Scroll` / `ScrollView` - スクロールビュー
   - その他、SwiftJsonUIで定義されているタイプ

4. **変換時の注意**
   - SwiftJsonUIの属性をSwiftUIの対応するモディファイアに変換
   - 存在しない属性は無視するか、適切なデフォルト値を使用
   - カスタムコンポーネント（TextViewWithPlaceholderなど）が必要な場合は、SwiftJsonUIの仕様に合わせて実装

## 実装時のチェックリスト

- [ ] JSONキー名はSwiftJsonUIの仕様に従っているか
- [ ] 同じJSONがSwiftJsonUIでも動作するか
- [ ] 不要なSwiftUI専用の属性を追加していないか
- [ ] 変換ロジックが正しく実装されているか

## 参考

SwiftJsonUIの仕様については、binding_builderのJSONファイルやドキュメントを参照してください。