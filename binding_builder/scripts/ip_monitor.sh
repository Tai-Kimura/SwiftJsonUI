#!/bin/bash

# IP変更監視スクリプト - HotLoader用Info.plist自動更新
# 使用方法: ./ip_monitor.sh [&] でバックグラウンド実行

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
INFO_PLIST="$PROJECT_ROOT/bindingTestApp/Info.plist"
LOG_FILE="$SCRIPT_DIR/ip_monitor.log"
CURRENT_IP_FILE="$SCRIPT_DIR/.current_ip"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

get_local_ip() {
    local ip=$(ipconfig getifaddr en0 2>/dev/null)
    if [ -z "$ip" ]; then
        ip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | grep -v "169.254" | head -n1 | awk '{print $2}')
    fi
    echo "$ip"
}

update_info_plist() {
    local new_ip="$1"
    local port="8081"
    
    log_message "Updating Info.plist with IP: $new_ip, Port: $port"
    
    if [ ! -f "$INFO_PLIST" ]; then
        log_message "Error: Info.plist not found at $INFO_PLIST"
        return 1
    fi
    
    # CurrentIpキーの設定
    if /usr/libexec/PlistBuddy -c "Print :CurrentIp" "$INFO_PLIST" 2>/dev/null; then
        /usr/libexec/PlistBuddy -c "Set :CurrentIp $new_ip" "$INFO_PLIST"
    else
        /usr/libexec/PlistBuddy -c "Add :CurrentIp string $new_ip" "$INFO_PLIST"
    fi
    
    # HotLoader Portキーの設定（スペース入り）
    if /usr/libexec/PlistBuddy -c "Print :HotLoader\ Port" "$INFO_PLIST" 2>/dev/null; then
        /usr/libexec/PlistBuddy -c "Set :HotLoader\ Port $port" "$INFO_PLIST"
    else
        /usr/libexec/PlistBuddy -c "Add :HotLoader\ Port string $port" "$INFO_PLIST"
    fi
    
    log_message "✅ Info.plist updated successfully"
    return 0
}

start_server_if_needed() {
    local hotload_server_dir="$PROJECT_ROOT/bindingTestApp/hot_loader"
    
    if [ ! -d "$hotload_server_dir" ]; then
        log_message "Warning: HotLoad server directory not found"
        return 1
    fi
    
    if lsof -ti:8081 >/dev/null 2>&1; then
        log_message "HotLoad server is already running on port 8081"
        return 0
    fi
    
    log_message "Starting HotLoad server..."
    cd "$hotload_server_dir"
    
    if [ ! -f "server.js" ]; then
        log_message "Warning: server.js not found"
        return 1
    fi
    
    if [ ! -d "node_modules" ]; then
        log_message "Installing Node.js dependencies..."
        npm install >/dev/null 2>&1
    fi
    
    nohup node server.js > server.log 2>&1 &
    
    for i in {1..10}; do
        if lsof -ti:8081 >/dev/null 2>&1; then
            log_message "✅ HotLoad server started successfully"
            return 0
        fi
        sleep 0.5
    done
    
    log_message "Warning: HotLoad server may not have started properly"
    return 1
}

monitor_ip_changes() {
    log_message "Starting IP address monitoring..."
    log_message "Project: $PROJECT_ROOT"
    log_message "Info.plist: $INFO_PLIST"
    
    local current_ip=""
    local stored_ip=""
    
    # 保存されているIPを読み込み
    if [ -f "$CURRENT_IP_FILE" ]; then
        stored_ip=$(cat "$CURRENT_IP_FILE")
    fi
    
    while true; do
        current_ip=$(get_local_ip)
        
        if [ -n "$current_ip" ] && [ "$current_ip" != "$stored_ip" ]; then
            log_message "IP address changed from '$stored_ip' to '$current_ip'"
            
            if update_info_plist "$current_ip"; then
                echo "$current_ip" > "$CURRENT_IP_FILE"
                start_server_if_needed
                log_message "HotLoader configuration updated for IP: $current_ip"
            else
                log_message "Failed to update Info.plist"
            fi
        fi
        
        sleep 5  # 5秒ごとにチェック
    done
}

show_help() {
    echo "IP Monitor Script for HotLoader"
    echo "Usage:"
    echo "    $0 start    - Start monitoring (foreground)"
    echo "    $0 daemon   - Start monitoring (background)"
    echo "    $0 stop     - Stop monitoring"
    echo "    $0 status   - Show current status"
    echo "    $0 update   - Force update now"
    echo "    $0 help     - Show this help"
}

case "${1:-start}" in
    "start")
        monitor_ip_changes
        ;;
    "daemon")
        log_message "Starting IP monitor as daemon..."
        nohup "$0" start > /dev/null 2>&1 &
        echo $! > "$SCRIPT_DIR/.ip_monitor.pid"
        log_message "IP monitor daemon started with PID: $!"
        ;;
    "stop")
        if [ -f "$SCRIPT_DIR/.ip_monitor.pid" ]; then
            pid=$(cat "$SCRIPT_DIR/.ip_monitor.pid")
            if kill "$pid" 2>/dev/null; then
                log_message "IP monitor daemon stopped (PID: $pid)"
                rm -f "$SCRIPT_DIR/.ip_monitor.pid"
            else
                log_message "Failed to stop daemon or daemon not running"
            fi
        else
            log_message "No daemon PID file found"
        fi
        ;;
    "status")
        if [ -f "$SCRIPT_DIR/.ip_monitor.pid" ]; then
            pid=$(cat "$SCRIPT_DIR/.ip_monitor.pid")
            if kill -0 "$pid" 2>/dev/null; then
                current_ip=$(get_local_ip)
                log_message "IP monitor daemon is running (PID: $pid)"
                log_message "Current IP: $current_ip"
            else
                log_message "Daemon PID file exists but process not running"
                rm -f "$SCRIPT_DIR/.ip_monitor.pid"
            fi
        else
            log_message "IP monitor daemon is not running"
        fi
        ;;
    "update")
        current_ip=$(get_local_ip)
        log_message "Force updating with current IP: $current_ip"
        if update_info_plist "$current_ip"; then
            echo "$current_ip" > "$CURRENT_IP_FILE"
            start_server_if_needed
        fi
        ;;
    "help"|*)
        show_help
        ;;
esac