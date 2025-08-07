#!/usr/bin/env ruby

require "fileutils"
require "pathname"
require_relative 'project_finder'
require_relative 'config_manager'
require_relative 'xcode_target_helper'

module SjuiTools
  module Core
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
            # Open project with xcodeproj gem
            require 'xcodeproj'
            
            # Determine project path
            if @project_file_path.end_with?('.xcodeproj')
              project = Xcodeproj::Project.open(@project_file_path)
              project_dir = File.dirname(@project_file_path)
            elsif @project_file_path.end_with?('.pbxproj')
              xcodeproj_path = File.dirname(File.dirname(@project_file_path))
              project = Xcodeproj::Project.open(xcodeproj_path)
              project_dir = File.dirname(xcodeproj_path)
            else
              # Try to find .xcodeproj in the directory
              xcodeproj_files = Dir.glob(File.join(@project_file_path, '*.xcodeproj'))
              if xcodeproj_files.empty?
                puts "Error: No .xcodeproj file found in #{@project_file_path}"
                return
              end
              project = Xcodeproj::Project.open(xcodeproj_files.first)
              project_dir = @project_file_path
            end
            
            # Get source directory from config
            config = Core::ConfigManager.load_config
            source_directory = config['source_directory'] || ''
            
            # The actual source path
            source_path = source_directory.empty? ? project_dir : File.join(project_dir, source_directory)
            
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
              'node_modules',
              'DerivedData',
              'build',
              '.idea',
              '.vscode'
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
              'package-lock.json',
              'yarn.lock',
              '.swiftlint.yml',
              '.jazzy.yaml',
              'Cartfile',
              'Cartfile.resolved',
              'Fastfile',
              'Appfile',
              '.env',
              '.env.local',
              '.env.production'
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
                  # Get relative path from source directory
                  relative_path = Pathname.new(file_path).relative_path_from(Pathname.new(source_path)).to_s
                  excluded_files << relative_path
                end
                puts "  Found #{Dir.glob("#{dir_path}/**/*", File::FNM_DOTMATCH).select{|f| !File.directory?(f)}.size} files in #{dir}" if dir.include?('node_modules')
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
            
            # Debug: Show some node_modules files if found
            node_modules_files = excluded_files.select { |f| f.include?('node_modules') }
            if node_modules_files.any?
              puts "  Including #{node_modules_files.size} files from node_modules directories"
              puts "  Sample: #{node_modules_files.first(3).join(', ')}" if node_modules_files.size > 0
            else
              puts "  Warning: No node_modules files found in exclusion list"
            end
            
            # Use xcodeproj to update membership exceptions
            # Find the main group that represents the synchronized folder
            main_group = project.main_group
            
            # For Xcode 15+ synchronized projects, we need to find the PBXFileSystemSynchronizedRootGroup
            synchronized_groups = project.root_object.main_group.children.select do |child|
              child.respond_to?(:isa) && child.isa == 'PBXFileSystemSynchronizedRootGroup'
            end
            
            if synchronized_groups.empty?
              puts "No synchronized groups found in project"
              return
            end
            
            # For Xcode 15+ synchronized projects, we need to find the exception sets differently
            # They are stored as PBXFileSystemSynchronizedBuildFileExceptionSet objects
            
            puts "Searching for exception sets in synchronized project..."
            
            # Find all exception set objects in the project
            exception_sets = []
            project.objects.each do |uuid, obj|
              if obj.respond_to?(:isa) && obj.isa == 'PBXFileSystemSynchronizedBuildFileExceptionSet'
                exception_sets << obj
                puts "Found exception set: #{uuid}"
              end
            end
            
            if exception_sets.empty?
              puts "Warning: No exception sets found. Creating them may require opening the project in Xcode first."
              return
            end
            
            # Update each exception set
            exception_sets.each do |exception_set|
              # Get current exceptions
              current_exceptions = exception_set.instance_variable_get(:@simple_attributes_hash)['membershipExceptions'] || []
              
              puts "Current exceptions count: #{current_exceptions.size}"
              
              # Convert to set for uniqueness
              exceptions_set = Set.new(current_exceptions)
              
              # Add our exclusions
              excluded_files.each do |file|
                exceptions_set.add(file)
              end
              
              # Update the exceptions
              exception_set.instance_variable_get(:@simple_attributes_hash)['membershipExceptions'] = exceptions_set.to_a.sort
              
              puts "✅ Updated to #{exceptions_set.size} membership exceptions"
            end
            
            # Save the project
            project.save
            
            # For synchronized projects, we need to manually write the membershipExceptions
            # because xcodeproj gem doesn't fully support Xcode 15+ format
            update_membership_exceptions_directly(excluded_files)
            
            puts "✅ Successfully updated membership exceptions for synchronized project"
            
          rescue LoadError
            puts "Error: xcodeproj gem not found. Please install it with: gem install xcodeproj"
            raise
          rescue => e
            puts "Error setting up synchronized exceptions with xcodeproj: #{e.message}"
            puts e.backtrace.first(5).join("\n") if ENV['DEBUG']
            raise e
          end
        end
        
        private
        
        def update_membership_exceptions_directly(excluded_files)
          # Read the project.pbxproj file
          pbxproj_path = if @project_file_path.end_with?('.pbxproj')
                          @project_file_path
                        elsif @project_file_path.end_with?('.xcodeproj')
                          File.join(@project_file_path, 'project.pbxproj')
                        else
                          File.join(@project_file_path, '*.xcodeproj', 'project.pbxproj')
                        end
          
          # Handle glob pattern if needed
          if pbxproj_path.include?('*')
            matching_files = Dir.glob(pbxproj_path)
            pbxproj_path = matching_files.first if matching_files.any?
          end
          
          unless File.exist?(pbxproj_path)
            puts "Warning: Could not find project.pbxproj at #{pbxproj_path}"
            return
          end
          
          puts "Directly updating membership exceptions in: #{pbxproj_path}"
          
          # Read the file
          content = File.read(pbxproj_path)
          
          # Find all PBXFileSystemSynchronizedBuildFileExceptionSet sections
          # and update their membershipExceptions
          updated_content = content.gsub(/membershipExceptions\s*=\s*\([^)]*\)/m) do |match|
            # Extract current exceptions
            current_exceptions = match.scan(/^\s*([^,\s][^,]*[^,\s])\s*,?$/m).flatten
            
            # Remove quotes if present
            current_exceptions = current_exceptions.map { |e| e.gsub(/^["']|["']$/, '') }
            
            # Add our exclusions
            all_exceptions = (current_exceptions + excluded_files).uniq.sort
            
            # Format the new exceptions list
            exceptions_formatted = all_exceptions.map { |f| 
              # Add quotes if the path contains spaces or special characters
              if f.include?(' ') || f.include?('/') || f.include?('-')
                "\"#{f}\""
              else
                f
              end
            }.join(",\n\t\t\t\t")
            
            # Return the updated membershipExceptions
            if all_exceptions.empty?
              "membershipExceptions = ("
            else
              "membershipExceptions = (\n\t\t\t\t#{exceptions_formatted},\n\t\t\t)"
            end
          end
          
          # Write the updated content back
          File.write(pbxproj_path, updated_content)
          
          puts "✅ Directly updated #{excluded_files.size} membership exceptions in project.pbxproj"
        end
        
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