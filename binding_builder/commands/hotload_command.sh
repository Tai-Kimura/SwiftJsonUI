#!/usr/bin/env bash

# hotload command - Manage HotLoader IP monitoring

hotload_command() {
    local SCRIPT_DIR="$1"
    local PROJECT_FILE="$2"
    shift 2
    
    HOTLOAD_COMMAND="$1"
    IP_MONITOR_SCRIPT="$SCRIPT_DIR/scripts/ip_monitor.sh"
    
    if [ ! -f "$IP_MONITOR_SCRIPT" ]; then
        echo "Error: IP monitor script not found at $IP_MONITOR_SCRIPT"
        return 1
    fi
    
    case "$HOTLOAD_COMMAND" in
        "start")
            echo "Starting IP monitor (foreground)..."
            "$IP_MONITOR_SCRIPT" start
            ;;
            
        "daemon")
            echo "Starting IP monitor (background)..."
            "$IP_MONITOR_SCRIPT" daemon
            ;;
            
        "listen")
            echo "🚀 Starting HotLoad development environment..."
            echo ""
            
            # Step 1: Update Info.plist with current IP
            echo "📝 Updating Info.plist with current IP..."
            "$IP_MONITOR_SCRIPT" update
            
            # Step 2: Start Node.js HotLoad server
            echo "🔥 Starting HotLoad server..."
            HOTLOAD_BUILD_SCRIPT="$SCRIPT_DIR/scripts/hotload_build_phase.sh"
            
            if [ ! -f "$HOTLOAD_BUILD_SCRIPT" ]; then
                echo "❌ Error: HotLoad build script not found at $HOTLOAD_BUILD_SCRIPT"
                return 1
            fi
            
            # Load configuration for plist path
            CONFIG_FILE="$SCRIPT_DIR/config/hotload.config"
            if [ -f "$CONFIG_FILE" ]; then
                source "$CONFIG_FILE"
            else
                PLIST_PATH="Info.plist"
            fi
            
            # Load source_directory from config.json
            CONFIG_JSON="$SCRIPT_DIR/config.json"
            if [ -f "$CONFIG_JSON" ]; then
                SOURCE_DIR=$(grep -o '"source_directory"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_JSON" | sed 's/.*"source_directory"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            else
                SOURCE_DIR=""
            fi
            
            # Set required environment variables for the script
            export CONFIGURATION="Debug"
            PROJECT_DIR_PARENT="$(dirname "$PROJECT_FILE")"
            if [ -z "$SOURCE_DIR" ]; then
                export PROJECT_DIR="$PROJECT_DIR_PARENT"
            else
                export PROJECT_DIR="$PROJECT_DIR_PARENT/$SOURCE_DIR"
            fi
            export INFOPLIST_FILE="$PLIST_PATH"
            
            # Execute the HotLoad build script
            "$HOTLOAD_BUILD_SCRIPT"
            
            # Step 3: Start IP monitor in background
            echo "🔄 Starting IP monitor daemon..."
            "$IP_MONITOR_SCRIPT" daemon
            
            echo ""
            echo "✅ HotLoad development environment started successfully!"
            echo ""
            echo "📊 Status:"
            echo "   - HotLoad server is running on port 8081"
            echo "   - IP monitor is running in background"
            echo "   - Layout files will auto-reload when changed"
            echo ""
            echo "🛠️  Management commands:"
            echo "   - Use 'sjui hotload status' to check status"
            echo "   - Use 'sjui hotload stop' to stop all services"
            ;;
            
        "stop")
            echo "🛑 Stopping HotLoad development environment..."
            echo ""
            
            # Stop IP monitor
            echo "Stopping IP monitor..."
            "$IP_MONITOR_SCRIPT" stop
            
            # Stop Node.js server (port 8081)
            echo "Stopping HotLoad server..."
            NODE_PID=$(lsof -ti:8081 2>/dev/null)
            if [ -n "$NODE_PID" ]; then
                kill $NODE_PID 2>/dev/null
                if [ $? -eq 0 ]; then
                    echo "✅ HotLoad server stopped (PID: $NODE_PID)"
                else
                    echo "⚠️  Failed to stop HotLoad server"
                fi
            else
                echo "ℹ️  HotLoad server was not running"
            fi
            
            # Stop any remaining Node.js processes related to HotLoad
            echo "Cleaning up any remaining HotLoad processes..."
            pkill -f "node.*server.js" 2>/dev/null
            pkill -f "node.*layout_loader.js" 2>/dev/null
            
            echo ""
            echo "✅ HotLoad development environment stopped"
            ;;
            
        "status")
            echo "📊 HotLoad Development Environment Status"
            echo "========================================"
            echo ""
            
            # IP Monitor status
            echo "🔄 IP Monitor:"
            "$IP_MONITOR_SCRIPT" status
            echo ""
            
            # Node.js HotLoad server status
            echo "🔥 HotLoad Server:"
            NODE_PID=$(lsof -ti:8081 2>/dev/null)
            if [ -n "$NODE_PID" ]; then
                echo "   ✅ Status: Running (PID: $NODE_PID)"
                echo "   🌐 Port: 8081"
                
                # Load configuration for plist path
                CONFIG_FILE="$SCRIPT_DIR/config/hotload.config"
                if [ -f "$CONFIG_FILE" ]; then
                    source "$CONFIG_FILE"
                else
                    PLIST_PATH="Info.plist"
                fi
                
                # Load source_directory from config.json
                CONFIG_JSON="$SCRIPT_DIR/config.json"
                if [ -f "$CONFIG_JSON" ]; then
                    SOURCE_DIR=$(grep -o '"source_directory"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_JSON" | sed 's/.*"source_directory"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
                else
                    SOURCE_DIR=""
                fi
                
                # Get current IP from Info.plist
                PROJECT_DIR_PARENT="$(dirname "$PROJECT_FILE")"
                
                if [[ "$PLIST_PATH" == /* ]]; then
                    # Absolute path
                    FULL_PLIST_PATH="$PLIST_PATH"
                else
                    # Relative path
                    if [ -z "$SOURCE_DIR" ]; then
                        FULL_PLIST_PATH="$PROJECT_DIR_PARENT/$PLIST_PATH"
                    else
                        FULL_PLIST_PATH="$PROJECT_DIR_PARENT/$SOURCE_DIR/$PLIST_PATH"
                    fi
                fi
                
                if [ -f "$FULL_PLIST_PATH" ]; then
                    CURRENT_IP=$(/usr/libexec/PlistBuddy -c "Print :CurrentIp" "$FULL_PLIST_PATH" 2>/dev/null || echo "Unknown")
                    echo "   🌍 Server URL: http://$CURRENT_IP:8081"
                fi
                
                # Check for specific Node.js processes
                SERVER_JS_PID=$(pgrep -f "node.*server.js" 2>/dev/null)
                LAYOUT_LOADER_PID=$(pgrep -f "node.*layout_loader.js" 2>/dev/null)
                
                if [ -n "$SERVER_JS_PID" ]; then
                    echo "   📡 server.js: Running (PID: $SERVER_JS_PID)"
                else
                    echo "   📡 server.js: Not detected"
                fi
                
                if [ -n "$LAYOUT_LOADER_PID" ]; then
                    echo "   📁 layout_loader.js: Running (PID: $LAYOUT_LOADER_PID)"
                else
                    echo "   📁 layout_loader.js: Not detected"
                fi
            else
                echo "   ❌ Status: Not running"
                echo "   💡 Use 'sjui hotload listen' to start the HotLoad server"
            fi
            
            echo ""
            echo "🛠️  Management Commands:"
            echo "   • sjui hotload listen  - Start full development environment"
            echo "   • sjui hotload stop    - Stop all HotLoad services"
            echo "   • sjui hotload update  - Update IP address in Info.plist"
            ;;
            
        "update")
            echo "Force updating Info.plist with current IP..."
            "$IP_MONITOR_SCRIPT" update
            ;;
            
        "")
            echo "Usage: sjui hotload <command>"
            echo "Available hotload commands:"
            echo "  listen   Start HotLoad server and IP monitor (full development environment)"
            echo "  start    Start IP monitor (foreground)"
            echo "  daemon   Start IP monitor (background)"
            echo "  stop     Stop HotLoad server and IP monitor"
            echo "  status   Show IP monitor status"
            echo "  update   Force update Info.plist with current IP"
            return 1
            ;;
            
        *)
            echo "Unknown hotload command: $HOTLOAD_COMMAND"
            echo "Run 'sjui hotload' to see available commands"
            return 1
            ;;
    esac
}