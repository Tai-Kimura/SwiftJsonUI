#!/usr/bin/env bash

# Convert command: Convert Xcode 16 synchronized folders to group references
convert_command() {
    local SCRIPT_DIR="$1"
    local PROJECT_FILE="$2"
    shift 2
    
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
    
    # Ensure we have the project.pbxproj path
    local pbxproj_path="$PROJECT_FILE"
    if [[ "$pbxproj_path" == *.xcodeproj ]]; then
        pbxproj_path="$pbxproj_path/project.pbxproj"
    fi
    
    if [ ! -f "$pbxproj_path" ]; then
        echo "Error: project.pbxproj not found at: $pbxproj_path"
        return 1
    fi
    
    echo "Using project: $pbxproj_path"
    
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