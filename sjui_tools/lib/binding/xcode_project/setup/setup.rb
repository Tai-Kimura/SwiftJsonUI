#!/usr/bin/env ruby

require "fileutils"
require "pathname"
require_relative '../pbxproj_manager'
require_relative '../../../core/project_finder'

module SjuiTools
  module Binding
    module XcodeProject
      module Setup
        class Setup < ::SjuiTools::Binding::XcodeProject::PbxprojManager
          def initialize(project_file_path = nil)
            super(project_file_path)
          end

          def run_full_setup
            puts "=== Starting SwiftJsonUI Project Setup ==="
            
            # 0. ワークスペースの存在を確認（SPM用）
            ensure_workspace_exists
            
            # 1. 変換後のプロジェクトの場合、既存ファイルを復元
            restore_converted_files
            
            # 2. ディレクトリ構造の作成
            setup_directories
            
            # 3. ライブラリパッケージの追加
            setup_libraries
            
            # 4. HotLoader機能の設定
            setup_hotloader
            
            # 5. Info.plistからStoryBoard参照を削除
            remove_storyboard_from_info_plist
            
            # 6. membershipExceptionsを設定
            setup_membership_exceptions
            
            puts "=== SwiftJsonUI Project Setup Completed Successfully! ==="
          end

          private

          def ensure_workspace_exists
            puts "Ensuring workspace exists..."
            
            # Get workspace path
            project_dir = File.dirname(@project_file_path)
            project_name = File.basename(@project_file_path, '.xcodeproj')
            workspace_path = File.join(project_dir, "#{project_name}.xcworkspace")
            
            # Create workspace directory if it doesn't exist
            unless Dir.exist?(workspace_path)
              FileUtils.mkdir_p(workspace_path)
              puts "Created workspace directory: #{workspace_path}"
              
              # Create basic workspace file
              workspace_data_path = File.join(workspace_path, 'contents.xcworkspacedata')
              unless File.exist?(workspace_data_path)
                workspace_xml = <<~XML
                  <?xml version="1.0" encoding="UTF-8"?>
                  <Workspace
                     version = "1.0">
                     <FileRef
                        location = "self:">
                     </FileRef>
                  </Workspace>
                XML
                File.write(workspace_data_path, workspace_xml)
                puts "Created workspace contents file"
              end
            else
              puts "Workspace already exists: #{workspace_path}"
            end
          end

          def setup_directories
            puts "Setting up project directories..."
            require_relative 'directory_setup'
            
            directory_setup = DirectorySetup.new(@project_file_path)
            directory_setup.create_missing_directories
          end

          def setup_libraries
            puts "Setting up required libraries..."
            require_relative '../../../core/setup/library_setup'
            
            library_setup = ::SjuiTools::Core::Setup::LibrarySetup.new(@project_file_path)
            library_setup.setup_libraries
          end

          def setup_hotloader
            puts "Setting up HotLoader functionality..."
            require_relative 'app_delegate_setup'
            
            app_delegate_setup = SjuiTools::Binding::XcodeProject::Setup::AppDelegateSetup.new(@project_file_path)
            app_delegate_setup.add_hotloader_functionality
          end


          def remove_storyboard_from_info_plist
            puts "Removing StoryBoard references from Info.plist..."
            
            # Info.plistファイルを探す
            # @project_file_pathが.xcodeprojかproject.pbxprojかを確認
            if @project_file_path.end_with?('.pbxproj')
              # project.pbxprojの場合は2階層上がプロジェクトディレクトリ
              project_dir = File.dirname(File.dirname(File.dirname(@project_file_path)))
            else
              # .xcodeprojディレクトリの場合は親ディレクトリがプロジェクトディレクトリ
              project_dir = File.dirname(@project_file_path)
            end
            
            info_plist_path = find_info_plist_file(project_dir)
            
            if info_plist_path.nil?
              puts "Warning: Could not find Info.plist file. StoryBoard references not removed."
              return
            end

            puts "Updating Info.plist: #{info_plist_path}"
            
            # Info.plistの内容を読み込む
            content = File.read(info_plist_path)
            
            # 既にStoryBoard参照が削除されているかチェック
            unless content.include?("UISceneStoryboardFile")
              puts "StoryBoard references already removed from Info.plist"
              return
            end
            
            # StoryBoard参照を削除
            updated_content = remove_storyboard_references(content)
            
            # ファイルに書き戻す
            File.write(info_plist_path, updated_content)
            puts "StoryBoard references removed from Info.plist successfully"
          end

          def find_info_plist_file(project_dir)
            # プロジェクトディレクトリから再帰的にInfo.plistを検索
            # ただし、DerivedData、Build、Pods、Carthageなどのディレクトリは除外
            info_plist_files = Dir.glob("#{project_dir}/**/Info.plist").reject do |path|
              path.include?('DerivedData') || 
              path.include?('Build') || 
              path.include?('Pods') || 
              path.include?('Carthage') ||
              path.include?('.build') ||
              path.include?('node_modules') ||
              path.include?('Tests') ||
              path.include?('UITests')
            end
            
            # 最もプロジェクトルートに近いものを選択
            info_plist_files.min_by { |path| path.split('/').length }
          end

          def remove_storyboard_references(content)
            # UISceneStoryboardFileキーとその値を削除
            content = content.gsub(/\s*<key>UISceneStoryboardFile<\/key>\s*\n\s*<string>.*?<\/string>\s*\n/, "")
            content
          end

          
          def restore_converted_files
            # 変換情報ファイルを確認
            project_dir = File.dirname(@project_file_path)
            conversion_info_path = File.join(project_dir, '.conversion_info.json')
            
            unless File.exist?(conversion_info_path)
              # 変換情報がない場合は何もしない（通常のsetup）
              return
            end
            
            puts "Found conversion info - processing converted project..."
            
            begin
              require 'json'
              conversion_info = JSON.parse(File.read(conversion_info_path))
              file_references = conversion_info['file_references'] || {}
              
              if file_references.empty?
                puts "No file references found in conversion info"
                return
              end
              
              puts "Conversion info contains references for: #{file_references.keys.join(', ')}"
              puts "Note: Existing files are preserved in their original locations"
              puts "      The convert command has already restored file references in the project"
              
              # 変換情報ファイルを削除（使用済み）
              File.delete(conversion_info_path)
              puts "Cleaned up conversion info file"
              
            rescue => e
              puts "Warning: Failed to process conversion info: #{e.message}"
              # エラーが発生しても処理を続行
            end
          end
        end
      end
    end
  end
end

# コマンドライン実行
if __FILE__ == $0
  begin
    # binding_builderディレクトリから検索開始
    binding_builder_dir = File.expand_path("../../../", __FILE__)
    project_file_path = ::SjuiTools::Core::ProjectFinder.find_project_file(binding_builder_dir)
    setup = ::SjuiTools::Binding::XcodeProject::Setup::Setup.new(project_file_path)
    setup.run_full_setup
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end