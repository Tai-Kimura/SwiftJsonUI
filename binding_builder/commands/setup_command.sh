#!/usr/bin/env bash

# setup command - Create directories and add them to Xcode project

setup_command() {
    local SCRIPT_DIR="$1"
    local PROJECT_FILE="$2"
    
    # Execute the Ruby setup script with project file path
    # Setup needs the full project.pbxproj path, not just the .xcodeproj directory
    SETUP_PROJECT_FILE="$PROJECT_FILE/project.pbxproj"
    ruby -e "
require '$SCRIPT_DIR/xcode_project/setup/setup'
setup = Setup.new(\"$SETUP_PROJECT_FILE\")
setup.run_full_setup
"
}