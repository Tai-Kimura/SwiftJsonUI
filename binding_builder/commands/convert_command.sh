#!/usr/bin/env bash

# Convert command: Convert Xcode 16 synchronized folders to group references
convert_command() {
    # Check for subcommand
    if [ $# -eq 0 ]; then
        echo "Usage: sjui convert <subcommand> [options]"
        echo ""
        echo "Available subcommands:"
        echo "  to-group    Convert Xcode 16 synchronized folders to group references"
        echo ""
        echo "Options:"
        echo "  --force, -f    Skip confirmation prompt"
        echo ""
        echo "Examples:"
        echo "  sjui convert to-group"
        echo "  sjui convert to-group --force"
        echo "  sjui convert to-group -f"
        return 1
    fi
    
    local subcommand=$1
    shift
    
    case $subcommand in
        to-group)
            convert_to_group "$@"
            ;;
        *)
            echo "Unknown convert subcommand: $subcommand"
            echo "Available: to-group"
            return 1
            ;;
    esac
}

# Convert to group references
convert_to_group() {
    local force_flag=false
    
    # Check for --force flag
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force|-f)
                force_flag=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                echo "Usage: sjui convert to-group [--force|-f]"
                return 1
                ;;
        esac
    done
    
    echo "Converting Xcode 16 synchronized folders to group references..."
    echo ""
    
    # Get project file path from environment or find it
    if [ -n "$PROJECT_FILE_PATH" ]; then
        # Use the already discovered project file
        local pbxproj_path="$PROJECT_FILE_PATH"
        echo "Using project: $pbxproj_path"
    else
        # Create a temporary Ruby script to find the project
        local temp_script=$(mktemp /tmp/find_project_XXXXXX.rb)
        cat > "$temp_script" <<'EOF'
#!/usr/bin/env ruby
require_relative ARGV[0] + '/project_finder'
require_relative ARGV[0] + '/config_manager'

base_dir = ARGV[0]
config = ConfigManager.load_config(base_dir)

begin
    if config['project_file_name'] && !config['project_file_name'].empty?
        puts ProjectFinder.find_project_file_by_name(base_dir, config['project_file_name'])
    else
        puts ProjectFinder.find_project_file(base_dir)
    end
rescue => e
    STDERR.puts e.message
    exit 1
end
EOF
        
        local pbxproj_path=$(ruby "$temp_script" "$SCRIPT_DIR/.." 2>&1)
        local ruby_exit_code=$?
        rm -f "$temp_script"
        
        if [ $ruby_exit_code -ne 0 ]; then
            echo "Error: $pbxproj_path"
            return 1
        fi
        
        echo "Found project: $pbxproj_path"
    fi
    
    echo ""
    
    # Check if force flag is set
    if [ "$force_flag" = true ]; then
        echo "Force mode enabled - skipping confirmation"
        ruby "$SCRIPT_DIR/tools/convert_to_group_reference.rb" "$pbxproj_path"
    else
        # Confirm before proceeding
        echo "⚠️  WARNING: This will modify your project file!"
        echo "A backup will be created, but please ensure Xcode is closed."
        echo ""
        read -p "Continue? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ruby "$SCRIPT_DIR/tools/convert_to_group_reference.rb" "$pbxproj_path"
        else
            echo "Cancelled."
            return 1
        fi
    fi
}