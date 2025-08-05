#!/usr/bin/env ruby

require_relative '../pbxproj_manager'
require_relative "destroyer"
require_relative '../../../core/config_manager'
require_relative '../../../core/project_finder'

module SjuiTools
  module Binding
    module XcodeProject
      class BindingDestroyer < Destroyer
        def initialize(project_file_path = nil)
          super(project_file_path)
          base_dir = File.expand_path('../..', File.dirname(__FILE__))
          
          # ProjectFinderを使用してパスを設定
          paths = Core::ProjectFinder.setup_paths(base_dir, @project_file_path)
          @bindings_path = paths.bindings_path
        end

        def destroy(view_name)
          # 名前の正規化
          camel_name = view_name.split('_').map(&:capitalize).join
          
          puts "Destroying binding files for: #{camel_name}"
          
          # 1. Bindingファイルパスの構築
          binding_path = "#{@bindings_path}/#{camel_name}Binding.swift"
          
          # 2. ファイルの存在確認
          files_to_remove = []
          
          if File.exist?(binding_path)
            files_to_remove << binding_path
          else
            puts "Warning: Binding file not found: #{binding_path}"
            return false
          end
          
          # 3. Xcodeプロジェクトから削除
          binding_file_name = "#{camel_name}Binding.swift"
          
          begin
            remove_from_xcode_project([binding_file_name], files_to_remove)
          rescue => e
            puts "Error removing from Xcode project: #{e.message}"
            return false
          end
          
          # 4. ファイルシステムからファイルを削除
          deleted_files = delete_files(files_to_remove)
          
          if deleted_files.any?
            puts "Successfully destroyed binding for: #{camel_name}"
            return true
          else
            puts "No binding files were destroyed for: #{camel_name}"
            return false
          end
        end

        def destroy_multiple(view_names)
          success_count = 0
          
          view_names.each do |view_name|
            if destroy(view_name)
              success_count += 1
            end
          end
          
          puts "Successfully destroyed #{success_count}/#{view_names.length} binding files"
          success_count == view_names.length
        end
      end
    end
  end
end

# コマンドライン実行
if __FILE__ == $0
  if ARGV.length < 1
    puts "Usage: ruby binding_destroyer.rb <view_name1> [view_name2] ..."
    puts "Example: ruby binding_destroyer.rb sample"
    puts "Example: ruby binding_destroyer.rb sample test_view another_view"
    exit 1
  end

  view_names = ARGV
  
  begin
    # binding_builderディレクトリから検索開始
    binding_builder_dir = File.expand_path("../../", __FILE__)
    project_file_path = SjuiTools::Core::ProjectFinder.find_project_file(binding_builder_dir)
    destroyer = SjuiTools::Binding::XcodeProject::BindingDestroyer.new(project_file_path)
    
    if view_names.length == 1
      destroyer.destroy(view_names.first)
    else
      destroyer.destroy_multiple(view_names)
    end
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end