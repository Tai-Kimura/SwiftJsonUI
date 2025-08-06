#!/usr/bin/env ruby

require "fileutils"
require "pathname"
require_relative '../../core/project_finder'
require_relative '../../core/config_manager'
require_relative '../../core/xcode_target_helper'

module SjuiTools
  module Binding
    module XcodeProject
      class PbxprojManager
        def initialize(project_file_path = nil)
          if project_file_path
            @project_file_path = project_file_path
            @project_root = Core::ProjectFinder.get_project_root(@project_file_path)
          else
            raise ArgumentError, "project_file_path is required"
          end
          
          # ConfigManagerを使用してsource_directoryを設定
          config = Core::ConfigManager.load_config
          @source_directory = config['source_directory'] || ''
          @hot_loader_directory = config['hot_loader_directory'] || ''
          
          # Check if synchronized project
          @is_synchronized = check_if_synchronized_project
        end
        
        def check_if_synchronized_project
          # Check if the project uses PBXFileSystemSynchronizedRootGroup
          begin
            if @project_file_path.end_with?('.pbxproj')
              content = File.read(@project_file_path)
            else
              # If it's a .xcodeproj directory, read the project.pbxproj inside
              pbxproj_path = File.join(@project_file_path, 'project.pbxproj')
              content = File.read(pbxproj_path)
            end
            
            content.include?('PBXFileSystemSynchronizedRootGroup')
          rescue => e
            puts "Warning: Could not check project type: #{e.message}"
            false
          end
        end


        def is_safe_file_path?(file_path)
          # Xcodeプロジェクトで問題を起こす可能性のある文字をチェック
          unsafe_chars = ['<', '>', ':', '"', '|', '?', '*', "\0"]
          unsafe_chars.none? { |char| file_path.include?(char) }
        end

        def setup_membership_exceptions
          return unless File.exist?(@project_file_path)
          
          puts "Setting up file exclusions..."
          
          # Check if synchronized project first
          if @is_synchronized
            setup_synchronized_exceptions
            return
          end
          
          begin
            require 'xcodeproj'
            
            # .xcodeprojディレクトリを見つける
            if @project_file_path.end_with?('.pbxproj')
              xcodeproj_path = File.dirname(File.dirname(@project_file_path))
            else
              xcodeproj_path = @project_file_path
            end
            
            # プロジェクトを開く
            project = Xcodeproj::Project.open(xcodeproj_path)
            
            # アプリターゲットを取得
            app_targets = Core::XcodeTargetHelper.get_app_targets(project)
            return if app_targets.empty?
            
            # 除外すべきディレクトリとファイル（XcodeProjectManagerから参照）
            excluded_patterns = ::SjuiTools::Binding::XcodeProjectManager::EXCLUDED_PATTERNS
            
            # パスからディレクトリとファイルを分離
            directories_to_exclude = excluded_patterns.select { |p| p.end_with?('/') }.map { |p| p.chomp('/') }
            files_to_exclude = excluded_patterns.reject { |p| p.end_with?('/') }
            
            # プロジェクトのメインルートグループを取得
            main_group = project.main_group
            
            # 各ターゲットから除外
            app_targets.each do |target|
              # ディレクトリの除外
              directories_to_exclude.each do |dir_name|
                if group = main_group.find_subpath(dir_name, true)
                  exclude_group_from_target(group, target)
                end
              end
              
              # ファイルの除外
              files_to_exclude.each do |file_name|
                # ルートグループ直下のファイルを探す
                file_ref = main_group.files.find { |f| f.name == file_name || f.path == file_name }
                if file_ref
                  # ビルドフェーズから除外
                  target.build_phases.each do |phase|
                    if phase.respond_to?(:files)
                      phase.files.each do |build_file|
                        if build_file.file_ref == file_ref
                          puts "Excluding file from target: #{file_name}"
                          phase.remove_build_file(build_file)
                        end
                      end
                    end
                  end
                end
              end
            end
            
            # プロジェクトを保存
            project.save
            puts "✅ Membership exceptions set successfully using xcodeproj gem"
            
          rescue LoadError
            puts "xcodeproj gem not found. Please install it with: gem install xcodeproj"
            raise LoadError, "xcodeproj gem is required for this operation"
          rescue => e
            puts "Error setting membership exceptions with xcodeproj: #{e.message}"
            raise e
          end
        end
        
        def setup_synchronized_exceptions
          puts "Setting up exclusions for synchronized project..."
          
          begin
            # Read project file content
            if @project_file_path.end_with?('.pbxproj')
              pbxproj_content = File.read(@project_file_path)
              xcodeproj_path = File.dirname(File.dirname(@project_file_path))
            else
              pbxproj_path = File.join(@project_file_path, 'project.pbxproj')
              pbxproj_content = File.read(pbxproj_path)
              xcodeproj_path = @project_file_path
            end
            
            # Get project directory
            project_dir = File.dirname(xcodeproj_path)
            
            # Get source directory from config
            config = Core::ConfigManager.load_config
            source_directory = config['source_directory'] || ''
            
            # The actual source path
            if source_directory.empty?
              source_path = project_dir
            else
              source_path = File.join(project_dir, source_directory)
            end
            
            # Find all files that should be excluded
            excluded_files = []
            
            # Directories to exclude (relative to source directory)
            directories_to_exclude = [
              'sjui_tools',
              '.git',
              '.github',
              '.build',
              '.swiftpm',
              'Tests',
              'UITests',
              'Docs',
              'docs',
              'config',
              'installer',
              'node_modules'
            ]
            
            # Files to exclude
            files_to_exclude = [
              'README.md',
              'LICENSE',
              'CHANGELOG.md',
              '.DS_Store',
              '.gitignore',
              'Podfile',
              'Podfile.lock',
              'Package.swift',
              'Package.resolved',
              'VERSION',
              '.ruby-version',
              'Gemfile',
              'Gemfile.lock',
              '.editorconfig',
              '.eslintrc',
              '.npmignore',
              '.nycrc',
              'FUNDING.yml',
              '.prettierrc',
              '.babelrc',
              '.travis.yml',
              '.package-lock.json'
            ]
            
            # Find all files in excluded directories
            directories_to_exclude.each do |dir|
              dir_path = File.join(source_path, dir)
              if Dir.exist?(dir_path)
                # Use File::FNM_DOTMATCH to include dot files
                Dir.glob("#{dir_path}/**/*", File::FNM_DOTMATCH).each do |file_path|
                  next if File.directory?(file_path)
                  # Skip . and .. entries
                  basename = File.basename(file_path)
                  next if basename == '.' || basename == '..'
                  # Get relative path from source directory (not project directory)
                  relative_path = Pathname.new(file_path).relative_path_from(Pathname.new(source_path)).to_s
                  excluded_files << relative_path
                end
              end
            end
            
            # Add standalone excluded files
            files_to_exclude.each do |file|
              file_path = File.join(source_path, file)
              if File.exist?(file_path)
                # Get relative path from source directory
                relative_path = Pathname.new(file_path).relative_path_from(Pathname.new(source_path)).to_s
                excluded_files << relative_path
              end
            end
            
            if excluded_files.empty?
              puts "No files to exclude found"
              return
            end
            
            puts "Found #{excluded_files.length} files to exclude"
            
            # Find the exception set in the project file
            if pbxproj_content =~ /membershipExceptions\s*=\s*\((.*?)\);/m
              current_exceptions = $1.strip.split(",").map(&:strip)
              
              # Add new exclusions
              all_exceptions = (current_exceptions + excluded_files).uniq
              
              # Format the exceptions list
              formatted_exceptions = all_exceptions.map { |f| "\t\t\t\t\"#{f}\"" }.join(",\n")
              
              # Replace in content
              new_content = pbxproj_content.gsub(
                /membershipExceptions\s*=\s*\((.*?)\);/m,
                "membershipExceptions = (\n#{formatted_exceptions}\n\t\t\t);"
              )
              
              # Write back
              if @project_file_path.end_with?('.pbxproj')
                File.write(@project_file_path, new_content)
              else
                File.write(File.join(@project_file_path, 'project.pbxproj'), new_content)
              end
              
              puts "✅ Updated membership exceptions for synchronized project"
            else
              puts "Warning: Could not find membershipExceptions in project file"
            end
            
          rescue => e
            puts "Error setting up synchronized exceptions: #{e.message}"
            raise e
          end
        end
        
        private
        
        def exclude_group_from_target(group, target)
          # グループ内のすべてのファイルを再帰的に除外
          group.recursive_children.each do |child|
            if child.is_a?(Xcodeproj::Project::Object::PBXFileReference)
              # ファイルがターゲットのビルドフェーズに含まれている場合は削除
              target.source_build_phase.files.each do |build_file|
                if build_file.file_ref == child
                  build_file.remove_from_project
                end
              end
              
              target.resources_build_phase.files.each do |build_file|
                if build_file.file_ref == child
                  build_file.remove_from_project
                end
              end
            end
          end
        end

      end
    end
  end
end