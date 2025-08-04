#!/usr/bin/env bash

# init command - Initialize config.json file

init_command() {
    local SCRIPT_DIR="$1"
    local PROJECT_FINDER_SCRIPT="$2"
    shift 2
    local ENVIRONMENTS=("$@")
    
    # Function to create config file
    create_config_file() {
        local CONFIG_FILE="$1"
        local FOUND_PROJECT_NAME="$2"
        local SOURCE_DIR="$3"
        local HOT_LOADER_DIR="$4"
        
        if [ -f "$CONFIG_FILE" ]; then
            echo "$CONFIG_FILE already exists"
            read -p "Do you want to overwrite it? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Skipping $CONFIG_FILE"
                return 0
            fi
        fi
        
        cat > "$CONFIG_FILE" << EOF
{
  "project_name": "$FOUND_PROJECT_NAME",
  "project_file_name": "$FOUND_PROJECT_NAME",
  "source_directory": "$SOURCE_DIR",
  "layouts_directory": "Layouts",
  "bindings_directory": "Bindings",
  "view_directory": "View",
  "styles_directory": "Styles",
  "build_settings": {
    "auto_build": false,
    "clean_before_build": false
  },
  "generator_settings": {
    "create_layout_file": true,
    "create_binding_file": true,
    "add_to_xcode_project": true
  },
  "custom_view_types": {
    "_comment": "カスタムビュータイプの設定例:",
    "_example": {
      "CustomButton": {
        "class_name": "UIButton",
        "import_module": "UIKit"
      },
      "WebView": {
        "class_name": "WKWebView", 
        "import_module": "WebKit"
      }
    }
  },
  "hot_loader_directory": "$HOT_LOADER_DIR",
  "use_network": true
}
EOF
        echo "Created $CONFIG_FILE"
    }
    
    # Find project file to set as default
    FOUND_PROJECT_FILE=$(echo "$PROJECT_FINDER_SCRIPT" | ruby - "$SCRIPT_DIR" "")
    if [ $? -ne 0 ]; then
        echo "Warning: Could not find Xcode project file. Setting project_file_name to empty string."
        FOUND_PROJECT_NAME=""
        SOURCE_DIR=""
        HOT_LOADER_DIR=""
    else
        # Extract project name from file path (e.g., pango.xcodeproj -> pango)
        FOUND_PROJECT_NAME=$(basename "$FOUND_PROJECT_FILE" .xcodeproj | sed 's/\.xcodeproj$//')
        if [ "$FOUND_PROJECT_NAME" = "project.pbxproj" ]; then
            # Handle case where we get the .pbxproj file path
            PARENT_DIR=$(dirname "$FOUND_PROJECT_FILE")
            FOUND_PROJECT_NAME=$(basename "$PARENT_DIR" .xcodeproj)
        fi
        
        # Detect source_directory based on project structure
        BINDING_BUILDER_PARENT=$(dirname "$SCRIPT_DIR")
        
        # The source directory is the directory containing the iOS app files
        # Check if the parent directory contains iOS app files (SwiftUI files have priority)
        if [ -f "$BINDING_BUILDER_PARENT/App.swift" -o -f "$BINDING_BUILDER_PARENT/ContentView.swift" -o -f "$BINDING_BUILDER_PARENT/AppDelegate.swift" -o -f "$BINDING_BUILDER_PARENT/SceneDelegate.swift" -o -f "$BINDING_BUILDER_PARENT/Info.plist" ]; then
            # If iOS files are in the same directory as binding_builder, use the directory name
            SOURCE_DIR=$(basename "$BINDING_BUILDER_PARENT")
            HOT_LOADER_DIR=$(basename "$BINDING_BUILDER_PARENT")
        else
            # Look for subdirectories containing iOS app files
            for dir in "$BINDING_BUILDER_PARENT"/*; do
                if [ -d "$dir" ] && [ "$(basename "$dir")" != "binding_builder" ] && [ -f "$dir/App.swift" -o -f "$dir/ContentView.swift" -o -f "$dir/AppDelegate.swift" -o -f "$dir/SceneDelegate.swift" -o -f "$dir/Info.plist" ]; then
                    SOURCE_DIR=$(basename "$dir")
                    HOT_LOADER_DIR=$(basename "$dir")
                    break
                fi
            done
            
            if [ -z "$SOURCE_DIR" ]; then
                SOURCE_DIR=""
                HOT_LOADER_DIR=""
            fi
        fi
    fi
    
    # Create base config.json
    CONFIG_FILE="$SCRIPT_DIR/config.json"
    create_config_file "$CONFIG_FILE" "$FOUND_PROJECT_NAME" "$SOURCE_DIR" "$HOT_LOADER_DIR"
    
    # Create environment-specific config files
    if [ ${#ENVIRONMENTS[@]} -gt 0 ]; then
        echo ""
        echo "Creating environment-specific config files..."
        for ENV in "${ENVIRONMENTS[@]}"; do
            ENV_CONFIG_FILE="$SCRIPT_DIR/${ENV}.config.json"
            create_config_file "$ENV_CONFIG_FILE" "$FOUND_PROJECT_NAME" "$SOURCE_DIR" "$HOT_LOADER_DIR"
        done
    fi
    
    echo ""
    echo "Initialization completed successfully!"
    if [ -n "$FOUND_PROJECT_NAME" ]; then
        echo "Project name set to: $FOUND_PROJECT_NAME"
    fi
    
    if [ ${#ENVIRONMENTS[@]} -gt 0 ]; then
        echo ""
        echo "Created config files:"
        echo "  - config.json (default)"
        for ENV in "${ENVIRONMENTS[@]}"; do
            echo "  - ${ENV}.config.json"
        done
    fi
}