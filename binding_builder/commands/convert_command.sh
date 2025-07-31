#!/usr/bin/env bash

# Convert command: Convert Xcode 16 synchronized folders to group references
convert_command() {
    # Check for subcommand
    if [ $# -eq 0 ]; then
        echo "Usage: sjui convert <subcommand>"
        echo ""
        echo "Available subcommands:"
        echo "  to-group    Convert Xcode 16 synchronized folders to group references"
        echo ""
        echo "Example:"
        echo "  sjui convert to-group"
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
    echo "Converting Xcode 16 synchronized folders to group references..."
    echo ""
    
    # Get project file path from environment or find it
    if [ -n "$PROJECT_FILE_PATH" ]; then
        # Use the already discovered project file
        ruby "$SCRIPT_DIR/tools/convert_to_group_reference.rb" "$PROJECT_FILE_PATH"
    else
        # Find project file first
        local project_file=$(find . -name "*.xcodeproj" -type d | head -1)
        if [ -z "$project_file" ]; then
            echo "Error: No Xcode project found in current directory"
            echo "Please run this command from your project directory"
            return 1
        fi
        
        local pbxproj_path="${project_file}/project.pbxproj"
        if [ ! -f "$pbxproj_path" ]; then
            echo "Error: project.pbxproj not found at: $pbxproj_path"
            return 1
        fi
        
        echo "Found project: $project_file"
        echo ""
        
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