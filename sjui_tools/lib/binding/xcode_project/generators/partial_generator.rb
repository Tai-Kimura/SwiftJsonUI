#!/usr/bin/env ruby

require "fileutils"
require "json"
require_relative '../pbxproj_manager'
require_relative '../../xcode_project_manager'
require_relative '../../../core/project_finder'

module SjuiTools
  module Binding
    module XcodeProject
      module Generators
        class PartialGenerator < ::SjuiTools::Binding::XcodeProject::PbxprojManager
          def initialize(project_file_path = nil)
            super(project_file_path)
            
            # Setup paths using ProjectFinder
            Core::ProjectFinder.setup_paths(@project_file_path)
            
            # Get configuration
            config = Core::ConfigManager.load_config
            
            # Set paths
            source_path = Core::ProjectFinder.get_full_source_path
            @layouts_path = File.join(source_path, config['layouts_directory'] || 'Layouts')
            
            @xcode_manager = SjuiTools::Binding::XcodeProjectManager.new(@project_file_path)
          end

          def generate(partial_name)
            puts "Generating partial layout: #{partial_name}"
            
            # 1. Partial JSONファイルの作成
            json_file_path = create_partial_json(partial_name)
            
            # 2. Xcodeプロジェクトに追加
            add_to_xcode_project(json_file_path)
            
            # 3. Bindingファイルの生成
            generate_binding_file
            
            puts "\nSuccessfully generated partial: #{partial_name}"
            puts "File created: #{json_file_path}"
            puts "\nTo use this partial, include it in your layout JSON:"
            puts '  {
    "type": "Partial",
    "name": "' + partial_name + '"
  }'
          end

          private

          def create_partial_json(partial_name)
            # Handle directory structure in partial name
            file_path = File.join(@layouts_path, "#{partial_name}.json")
            
            # Ensure parent directory exists
            parent_dir = File.dirname(file_path)
            unless Dir.exist?(parent_dir)
              FileUtils.mkdir_p(parent_dir)
              puts "Created directory: #{parent_dir}"
            end
            
            if File.exist?(file_path)
              puts "Warning: Partial JSON file already exists: #{file_path}"
              return file_path
            end
            
            content = generate_partial_json_content(partial_name)
            File.write(file_path, content)
            puts "Created partial JSON: #{file_path}"
            
            file_path
          end

          def generate_partial_json_content(partial_name)
            # Extract just the filename part for IDs (remove directory path)
            base_name = File.basename(partial_name)
            
            content = {
              "type" => "View",
              "id" => "#{base_name}_root",
              "width" => "matchParent",
              "height" => "wrapContent",
              "padding" => "16",
              "background" => "FFFFFF",
              "child" => [
                {
                  "type" => "Label",
                  "id" => "#{base_name}_label",
                  "text" => "This is the #{base_name} partial",
                  "textSize" => "14",
                  "textColor" => "000000"
                }
              ]
            }
            JSON.pretty_generate(content)
          end

          def add_to_xcode_project(json_file_path)
            # バックアップとエラーハンドリングを含む安全な処理
            @xcode_manager.add_file(json_file_path, "Layouts")
          end

          def generate_binding_file
            begin
              # JsonLoaderとImportModuleManagerをrequire
              require_relative '../../json_loader'
              require_relative '../../import_module_manager'
              require_relative '../../../core/config_manager'
              
              # configから カスタムビュータイプを読み込んで設定
              custom_view_types = Core::ConfigManager.get_custom_view_types
              
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
              
              # JsonLoaderを実行
              loader = JsonLoader.new(nil, @project_file_path)
              loader.start_analyze
              
              puts "Successfully generated binding files"
            rescue => e
              puts "Warning: Could not generate binding files: #{e.message}"
              puts "You can run 'sjui build' manually to generate binding files"
            end
          end
        end
      end
    end
  end
end

# コマンドライン実行
if __FILE__ == $0
  if ARGV.length != 1
    puts "Usage: ruby partial_generator.rb <partial_name>"
    puts "Example: ruby partial_generator.rb navigation_bar"
    exit 1
  end

  begin
    # binding_builderディレクトリから検索開始
    binding_builder_dir = File.expand_path("../../", __FILE__)
    project_file_path = SjuiTools::Core::ProjectFinder.find_project_file(binding_builder_dir)
    generator = SjuiTools::Binding::XcodeProject::Generators::PartialGenerator.new(project_file_path)
    generator.generate(ARGV[0])
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end