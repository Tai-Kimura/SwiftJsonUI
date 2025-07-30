#!/bin/bash

# HotLoad Build Phase Script
# このスクリプトはXcode Build Phaseで実行され、以下を行います：
# 1. IPアドレス検出
# 2. plistへのIP設定
# 3. Node.jsサーバー起動
# 4. レイアウトファイルのシンボリックリンク作成

# DEBUGビルドでのみ実行
if [ "${CONFIGURATION}" != "Debug" ]; then
    echo "Release build detected. Skipping HotLoad setup."
    exit 0
fi

echo "=== SwiftJsonUI HotLoad Setup ==="
echo "BUILD CONFIGURATION: ${CONFIGURATION}"
echo "PROJECT_DIR: ${PROJECT_DIR}"
echo "INFOPLIST_FILE: ${INFOPLIST_FILE}"

# binding_builderディレクトリへのパス設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINDING_BUILDER_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT_DIR="$(dirname "$BINDING_BUILDER_DIR")"

echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "BINDING_BUILDER_DIR: $BINDING_BUILDER_DIR"
echo "PROJECT_ROOT_DIR: $PROJECT_ROOT_DIR"

# configファイルからsource_directoryを取得
get_source_directory() {
    local config_file="$BINDING_BUILDER_DIR/config.json"
    local source_dir=""
    
    if [ -f "$config_file" ]; then
        # JSONからsource_directoryを抽出
        source_dir=$(grep -o '"source_directory"[[:space:]]*:[[:space:]]*"[^"]*"' "$config_file" | sed 's/.*"source_directory"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    fi
    
    echo "$source_dir"
}

# configファイルからhot_loader_directoryを取得
get_hot_loader_directory() {
    local config_file="$BINDING_BUILDER_DIR/config.json"
    local hot_loader_dir=""
    
    if [ -f "$config_file" ]; then
        # JSONからhot_loader_directoryを抽出
        hot_loader_dir=$(grep -o '"hot_loader_directory"[[:space:]]*:[[:space:]]*"[^"]*"' "$config_file" | sed 's/.*"hot_loader_directory"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        
        # 空の場合はproject_file_nameをフォールバック
        if [ -z "$hot_loader_dir" ]; then
            hot_loader_dir=$(grep -o '"project_file_name"[[:space:]]*:[[:space:]]*"[^"]*"' "$config_file" | sed 's/.*"project_file_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        fi
    fi
    
    # それでも空の場合はプロジェクト名を使用
    if [ -z "$hot_loader_dir" ]; then
        # PROJECT_DIRからプロジェクト名を取得
        hot_loader_dir=$(basename "$PROJECT_DIR")
    fi
    
    echo "$hot_loader_dir"
}

HOT_LOADER_DIR_NAME=$(get_hot_loader_directory)
# hot_loader_directoryが空の時はxcodeprojと同じディレクトリ、指定があったらそこから指定されたディレクトリに移動
if [ -z "$HOT_LOADER_DIR_NAME" ] || [ "$HOT_LOADER_DIR_NAME" = "" ]; then
    # xcodeprojと同じディレクトリ（PROJECT_ROOT_DIRの親）
    HOTLOAD_SERVER_DIR="$(dirname "$PROJECT_ROOT_DIR")/hot_loader"
else
    # 指定されたディレクトリ内
    HOTLOAD_SERVER_DIR="$(dirname "$PROJECT_ROOT_DIR")/$HOT_LOADER_DIR_NAME/hot_loader"
fi

echo "Project Dir: $PROJECT_DIR"
echo "Binding Builder Dir: $BINDING_BUILDER_DIR"
echo "Project Root Dir: $PROJECT_ROOT_DIR"
echo "Hot Loader Directory Config: $HOT_LOADER_DIR_NAME"
echo "HotLoad Server Dir: $HOTLOAD_SERVER_DIR"

# 1. IPアドレス検出
get_local_ip() {
    # WiFiインターフェースのIPアドレスを取得
    local ip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | grep -v "169.254" | head -n1 | awk '{print $2}')
    
    # 見つからない場合は別の方法で取得
    if [ -z "$ip" ]; then
        ip=$(route get default | grep interface | awk '{print $2}' | xargs ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n1)
    fi
    
    # それでも見つからない場合はデフォルト
    if [ -z "$ip" ]; then
        ip="192.168.1.100"
        echo "Warning: Could not detect IP address. Using default: $ip"
    fi
    
    echo "$ip"
}

LOCAL_IP=$(get_local_ip)
echo "Detected IP Address: $LOCAL_IP"

# 2. Info.plistにIPアドレスとポートを設定
update_plist_with_hotload_config() {
    local port="8081"
    
    # Info.plistのパスを動的に検出
    local plist_path=""
    if [ -n "$PROJECT_DIR" ] && [ -n "$INFOPLIST_FILE" ]; then
        # Xcode環境変数が利用可能な場合
        plist_path="$PROJECT_DIR/$INFOPLIST_FILE"
    else
        # 手動実行の場合、プロジェクトディレクトリから検索
        plist_path="$PROJECT_ROOT_DIR/Info.plist"
    fi
    
    echo "=== Updating plist ==="
    echo "Plist path: $plist_path"
    echo "Local IP: $LOCAL_IP"
    echo "Port: $port"
    
    if [ -f "$plist_path" ]; then
        echo "Info.plist found, updating..."
        # CurrentIpキーの設定
        if /usr/libexec/PlistBuddy -c "Print :CurrentIp" "$plist_path" 2>/dev/null; then
            # 既存のキーを更新
            /usr/libexec/PlistBuddy -c "Set :CurrentIp $LOCAL_IP" "$plist_path"
        else
            # 新しいキーを追加
            /usr/libexec/PlistBuddy -c "Add :CurrentIp string $LOCAL_IP" "$plist_path"
        fi
        
        # HotLoader Portキーの設定（スペースを含むキー名）
        if /usr/libexec/PlistBuddy -c "Print :HotLoader\ Port" "$plist_path" 2>/dev/null; then
            # 既存のキーを更新
            /usr/libexec/PlistBuddy -c "Set :HotLoader\ Port $port" "$plist_path"
        else
            # 新しいキーを追加
            /usr/libexec/PlistBuddy -c "Add :HotLoader\ Port string $port" "$plist_path"
        fi
        
        echo "✅ HotLoad config added to Info.plist - CurrentIp: $LOCAL_IP, HotLoader Port: $port"
    else
        echo "❌ Error: Info.plist not found at $plist_path"
        echo "Available files in PROJECT_DIR:"
        ls -la "$PROJECT_DIR" 2>/dev/null || echo "Cannot list PROJECT_DIR"
    fi
}

update_plist_with_hotload_config

# 3. Node.jsサーバーが既に起動しているかチェック
check_server_running() {
    local port=8081
    # WebSocketサーバーとして実際に接続可能かを確認
    # lsofでLISTEN状態のプロセスのみをチェック
    local listening_pid=$(lsof -ti:$port -sTCP:LISTEN 2>/dev/null)
    
    if [ -n "$listening_pid" ]; then
        # さらにnode server.jsプロセスかどうかを確認
        if ps -p $listening_pid -o command= | grep -q "node.*server.js"; then
            return 0  # server.jsが起動している
        fi
    fi
    
    return 1  # server.jsが起動していない
}

# 4. Node.jsサーバー起動
start_hotload_server() {
    if [ ! -d "$HOTLOAD_SERVER_DIR" ]; then
        echo "Warning: HotLoad server directory not found: $HOTLOAD_SERVER_DIR"
        return 1
    fi
    
    cd "$HOTLOAD_SERVER_DIR"
    
    # 必要なファイルが存在するかチェック
    if [ ! -f "server.js" ] || [ ! -f "layout_loader.js" ]; then
        echo "Warning: server.js or layout_loader.js not found in HotLoad server directory"
        return 1
    fi
    
    # node_modulesが存在しない場合はnpm install
    if [ ! -d "node_modules" ]; then
        echo "Installing Node.js dependencies..."
        npm install >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "Warning: npm install failed"
            return 1
        fi
    fi
    
    # layout_loader.jsが動作していない場合は起動
    if ! pgrep -f "node.*layout_loader.js" > /dev/null 2>&1; then
        echo "Starting layout_loader.js..."
        nohup node layout_loader.js > layout_loader.log 2>&1 &
        sleep 1
    else
        echo "layout_loader.js is already running"
    fi
    
    # server.jsが動作していない場合は起動
    if ! check_server_running; then
        echo "Starting server.js..."
        # 念のため古いCLOSED接続を持つプロセスをクリーンアップ
        OLD_PIDS=$(lsof -ti:8081 2>/dev/null)
        if [ -n "$OLD_PIDS" ]; then
            echo "Cleaning up stale connections on port 8081..."
            for pid in $OLD_PIDS; do
                # server.js以外のプロセスのみクリーンアップ
                if ! ps -p $pid -o command= | grep -q "node.*server.js"; then
                    kill -9 $pid 2>/dev/null
                fi
            done
            sleep 1
        fi
        
        nohup node server.js > server.log 2>&1 &
        sleep 1
    else
        echo "HotLoad server is already running on port 8081"
    fi
    
    # 起動確認（最大5秒待機）
    for i in {1..10}; do
        if check_server_running; then
            echo "HotLoad server started successfully on port 8081"
            echo "Both layout_loader.js and server.js are running"
            return 0
        fi
        sleep 0.5
    done
    
    echo "Warning: HotLoad server may not have started properly"
    return 1
}

# 5. レイアウトファイルのシンボリックリンク作成
setup_layout_symlinks() {
    local layouts_dir="$PROJECT_DIR/../Layouts"
    local public_dir="$HOTLOAD_SERVER_DIR/public"
    
    # publicディレクトリが存在しない場合は作成
    if [ ! -d "$public_dir" ]; then
        mkdir -p "$public_dir"
        echo "Created public directory: $public_dir"
    fi
    
    if [ -d "$layouts_dir" ]; then
        # 既存のシンボリックリンクを削除
        find "$public_dir" -type l -delete 2>/dev/null
        
        # JSONファイルのシンボリックリンクを作成
        find "$layouts_dir" -name "*.json" -exec ln -sf {} "$public_dir/" \;
        echo "Layout files linked to HotLoad server public directory"
        
        # リンクされたファイルを確認
        json_count=$(find "$layouts_dir" -name "*.json" | wc -l)
        echo "Linked $json_count JSON layout files"
    else
        echo "Layouts directory not found: $layouts_dir"
        echo "Note: Layout files will be linked when Layouts directory is created"
    fi
}

# Node.jsが利用可能かチェック
if ! command -v node >/dev/null 2>&1; then
    echo "Warning: Node.js not found. HotLoad server cannot be started."
    echo "Please install Node.js to use HotLoad functionality."
    exit 0
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "Warning: npm not found. HotLoad server cannot be started."
    exit 0
fi

# HotLoadサーバー起動
start_hotload_server

# レイアウトファイルのシンボリックリンク設定
setup_layout_symlinks

echo "=== HotLoad Setup Complete ==="
echo "Server IP: $LOCAL_IP:8081"
echo "Layout files are being monitored for changes"