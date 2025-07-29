#!/usr/bin/env bash

# destroy command - Destroy view components

destroy_command() {
    local SCRIPT_DIR="$1"
    local PROJECT_FILE="$2"
    shift 2
    
    SUBCOMMAND="$1"
    shift
    
    case "$SUBCOMMAND" in
        "view")
            if [ $# -eq 0 ]; then
                echo "Usage: sjui destroy view <view_name>"
                echo "Example: sjui destroy view sample"
                return 1
            fi
            
            # Execute the Ruby view destroyer with project file path
            # ViewDestroyer needs the full project.pbxproj path, not just the .xcodeproj directory
            VIEW_DEST_PROJECT_FILE="$PROJECT_FILE/project.pbxproj"
            ruby -e "
require '$SCRIPT_DIR/xcode_project/destroyers/view_destroyer'
destroyer = ViewDestroyer.new('$VIEW_DEST_PROJECT_FILE')
destroyer.destroy('$1')
"
            ;;
            
        *)
            echo "Unknown subcommand: $SUBCOMMAND"
            echo "Available subcommands for 'destroy':"
            echo "  view <view_name>    Destroy view controller and layout files"
            return 1
            ;;
    esac
}