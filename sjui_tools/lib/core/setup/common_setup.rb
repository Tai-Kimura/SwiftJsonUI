#!/usr/bin/env ruby

require "fileutils"
require "pathname"
require 'json'
require_relative '../pbxproj_manager'
require_relative '../project_finder'
require_relative '../xcode_project_manager'

module SjuiTools
  module Core
    module Setup
      class CommonSetup < ::SjuiTools::Core::PbxprojManager
        def initialize(project_file_path = nil)
          super(project_file_path)
        end

        # 0. ワークスペースの存在を確認（SPM用）
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
          else
            puts "Workspace already exists: #{workspace_path}"
          end
          
          # Always ensure workspace contents file exists
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
          
          # Create xcshareddata/swiftpm structure immediately
          shared_data_path = File.join(workspace_path, 'xcshareddata')
          swiftpm_path = File.join(shared_data_path, 'swiftpm')
          
          FileUtils.mkdir_p(swiftpm_path)
          puts "Created/verified SPM directory structure: #{swiftpm_path}"
          
          # Create empty Package.resolved if it doesn't exist
          package_resolved_path = File.join(swiftpm_path, 'Package.resolved')
          unless File.exist?(package_resolved_path)
            initial_resolved = {
              "object" => {
                "pins" => []
              },
              "version" => 1
            }
            File.write(package_resolved_path, JSON.pretty_generate(initial_resolved))
            puts "Created Package.resolved file"
          end
          
          # Create workspace configuration if needed
          workspace_settings_path = File.join(shared_data_path, 'WorkspaceSettings.xcsettings')
          unless File.exist?(workspace_settings_path)
            settings_xml = <<~XML
              <?xml version="1.0" encoding="UTF-8"?>
              <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
              <plist version="1.0">
              <dict>
                <key>IDEWorkspaceSharedSettings_AutocreateContextsIfNeeded</key>
                <false/>
              </dict>
              </plist>
            XML
            File.write(workspace_settings_path, settings_xml)
            puts "Created workspace settings file"
          end
        end

        # 3. ライブラリパッケージの追加
        def setup_libraries
          puts "Setting up required libraries..."
          require_relative 'library_setup'
          
          library_setup = ::SjuiTools::Core::Setup::LibrarySetup.new(@project_file_path)
          library_setup.setup_libraries
        end


        # 6. membershipExceptionsを設定
        def setup_membership_exceptions
          if is_synchronized_project?
            setup_synchronized_exceptions
          else
            setup_traditional_exceptions
          end
        end

        # 7. 不要な参照をクリーンアップ
        def cleanup_project_references
          puts "Cleaning up project references..."
          
          # Use XcodeProjectManager to clean up phantom references
          xcode_manager = ::SjuiTools::Core::XcodeProjectManager.new(@project_file_path)
          
          # This will trigger the cleanup
          xcode_manager.send(:cleanup_empty_groups)
          
          puts "Project references cleaned up"
        end

        private

        def is_synchronized_project?
          # Check if it's a synchronized project (Xcode 15+)
          if @project_file_path.end_with?('.pbxproj')
            pbxproj_content = File.read(@project_file_path)
          else
            pbxproj_path = File.join(@project_file_path, 'project.pbxproj')
            pbxproj_content = File.read(pbxproj_path)
          end
          
          pbxproj_content.include?('PBXFileSystemSynchronizedRootGroup')
        end
      end
    end
  end
end