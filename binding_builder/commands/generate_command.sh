#!/usr/bin/env bash

# generate command - Generate various components

generate_command() {
    local SCRIPT_DIR="$1"
    local PROJECT_FILE="$2"
    shift 2
    
    SUBCOMMAND="$1"
    shift
    
    case "$SUBCOMMAND" in
        "view")
            if [ $# -eq 0 ]; then
                echo "Usage: sjui generate view <view_name> [--root]"
                echo "Example: sjui generate view sample"
                echo "Example: sjui generate view sample --root"
                return 1
            fi
            
            VIEW_NAME="$1"
            IS_ROOT="false"
            shift
            
            # Parse additional options
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --root)
                        IS_ROOT="true"
                        shift
                        ;;
                    *)
                        echo "Unknown option: $1"
                        return 1
                        ;;
                esac
            done
            
            # Execute the Ruby view generator with project file path
            # ViewGenerator needs the full project.pbxproj path, not just the .xcodeproj directory
            VIEW_GEN_PROJECT_FILE="$PROJECT_FILE/project.pbxproj"
            ruby -e "
require '$SCRIPT_DIR/xcode_project/generators/view_generator'
generator = ViewGenerator.new('$VIEW_GEN_PROJECT_FILE')
generator.generate('$VIEW_NAME', $IS_ROOT)
"
            ;;
            
        "collection")
            if [ $# -eq 0 ]; then
                echo "Usage: sjui generate collection <ViewFolder>/<CellName>"
                echo "Example: sjui generate collection Sample/SampleList"
                return 1
            fi
            
            COLLECTION_ARGS="$1"
            
            # Execute the Ruby collection generator with project file path
            # CollectionGenerator needs the full project.pbxproj path, not just the .xcodeproj directory
            COLLECTION_GEN_PROJECT_FILE="$PROJECT_FILE/project.pbxproj"
            ruby -e "
require '$SCRIPT_DIR/xcode_project/generators/collection_generator'
generator = CollectionGenerator.new('$COLLECTION_GEN_PROJECT_FILE')
generator.generate('$COLLECTION_ARGS')
"
            ;;
            
        "partial")
            if [ $# -eq 0 ]; then
                echo "Usage: sjui generate partial <partial_name>"
                echo "Example: sjui generate partial navigation_bar"
                return 1
            fi
            
            PARTIAL_NAME="$1"
            
            # Execute the Ruby partial generator with project file path
            # PartialGenerator needs the full project.pbxproj path, not just the .xcodeproj directory
            PARTIAL_GEN_PROJECT_FILE="$PROJECT_FILE/project.pbxproj"
            ruby -e "
require '$SCRIPT_DIR/xcode_project/generators/partial_generator'
generator = PartialGenerator.new('$PARTIAL_GEN_PROJECT_FILE')
generator.generate('$PARTIAL_NAME')
"
            ;;
            
        *)
            echo "Unknown subcommand: $SUBCOMMAND"
            echo "Available subcommands for 'generate':"
            echo "  view <view_name>    Generate view controller and layout files"
            echo "  collection <ViewFolder>/<CellName>    Generate collection view cell"
            echo "  partial <partial_name>    Generate partial JSON layout"
            return 1
            ;;
    esac
}