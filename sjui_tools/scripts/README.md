# HotLoader IP Monitor

IPアドレスの変更を監視して、SwiftJsonUI HotLoaderの設定を自動的に更新するスクリプトです。

## 機能

- IPアドレスの変更を5秒間隔で監視
- 変更検出時にInfo.plistのCurrentIpとHotLoaderPortを自動更新
- HotLoadサーバーの自動起動
- バックグラウンド実行対応
- ログ出力

## 使用方法

### 基本コマンド

```bash
# スクリプトのあるディレクトリに移動
cd YourProject/binding_builder/scripts

# 現在のIPでInfo.plistを強制更新
./ip_monitor.sh update

# 監視開始（フォアグラウンド）
./ip_monitor.sh start

# 監視開始（バックグラウンド）
./ip_monitor.sh daemon

# 監視状況確認
./ip_monitor.sh status

# 監視停止
./ip_monitor.sh stop

# ヘルプ表示
./ip_monitor.sh help
```

### 推奨使用方法

### 🚀 簡単な方法（推奨）

SJUIコマンドを使用すると、すべて自動で実行されます：

```bash
# プロジェクトのbinding_builderディレクトリに移動
cd YourProject/binding_builder

# 開発環境を一発起動（IP監視 + Xcode起動）
./sjui run

# IP監視の状況確認
./sjui hotload status

# IP監視を停止
./sjui hotload stop
```

### 🔧 手動操作

より細かくコントロールしたい場合：

1. **初回設定**: `./ip_monitor.sh update` でInfo.plistを初期設定
2. **開発開始**: `./ip_monitor.sh daemon` でバックグラウンド監視開始
3. **状況確認**: `./ip_monitor.sh status` で動作確認
4. **開発終了**: `./ip_monitor.sh stop` で監視停止

## 動作の仕組み

1. **IP検出**: `ipconfig getifaddr en0` でプライマリネットワークのIPを取得
2. **変更検知**: 前回保存されたIPと比較して変更を検出
3. **Info.plist更新**: PlistBuddyを使用してCurrentIpとHotLoaderPortを更新
4. **サーバー起動**: 必要に応じてHotLoadサーバー(port 8081)を起動

## ファイル

- `ip_monitor.sh` - メインスクリプト
- `ip_monitor.log` - ログファイル
- `.current_ip` - 前回のIP保存ファイル
- `.ip_monitor.pid` - デーモンPIDファイル

## 設定されるInfo.plist項目

```xml
<key>CurrentIp</key>
<string>192.168.3.32</string>
<key>HotLoaderPort</key>
<string>8081</string>
```

## ネットワーク変更時の自動実行

Wi-Fi切り替えや有線⇔無線の変更時に、IPアドレスが変わると自動的にInfo.plistが更新され、アプリが正しいサーバーに接続できるようになります。

## トラブルシューティング

- **権限エラー**: スクリプトに実行権限があることを確認 `chmod +x ip_monitor.sh`
- **サーバー起動失敗**: hot_loaderディレクトリとserver.jsの存在を確認
- **IP検出失敗**: ネットワークアダプターの設定を確認

## ログ確認

```bash
tail -f ip_monitor.log
```