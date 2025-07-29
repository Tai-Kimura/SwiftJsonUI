#!/usr/bin/env bash

# build command - Build binding files from JSON layouts

build_command() {
    local SCRIPT_DIR="$1"
    local PROJECT_FILE="$2"
    
    # Execute the Ruby build script with project file path
    ruby -e "
require '$SCRIPT_DIR/json_loader'
require '$SCRIPT_DIR/project_finder'
require '$SCRIPT_DIR/import_module_manager'
require '$SCRIPT_DIR/config_manager'

# configから カスタムビュータイプを読み込んで設定
custom_view_types = ConfigManager.get_custom_view_types('$SCRIPT_DIR')

# カスタムビュータイプを設定
view_type_mappings = {}
import_mappings = {}

custom_view_types.each do |view_type, config|
  if config['class_name']
    view_type_mappings[view_type.to_sym] = config['class_name']
  end
  if config['import_module']
    import_mappings[view_type] = config['import_module']
  end
end

# View typeの拡張
JsonLoader.view_type_set.merge!(view_type_mappings) unless view_type_mappings.empty?

# Importマッピングの追加
import_mappings.each do |type, module_name|
  ImportModuleManager.add_type_import_mapping(type, module_name)
end

# JsonLoader needs the full project.pbxproj path, not just the .xcodeproj directory
BUILD_PROJECT_FILE = '$PROJECT_FILE/project.pbxproj'
loader = JsonLoader.new(nil, BUILD_PROJECT_FILE)
loader.start_analyze
"
}