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
          puts "=== setup_membership_exceptions called ==="
          puts "  Project file path: #{@project_file_path}"
          puts "  File exists: #{File.exist?(@project_file_path)}"
          
          return unless File.exist?(@project_file_path)
          
          puts "Setting up file exclusions..."
          puts "  Is synchronized project: #{@is_synchronized}"
          
          # Check if synchronized project first
          if @is_synchronized
            puts "  -> Calling setup_synchronized_exceptions"
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
            excluded_patterns = ::SjuiTools::UIKit::XcodeProjectManager::EXCLUDED_PATTERNS
            
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
          puts "  Called from: #{caller.first(3).join("\n    ")}" if ENV['DEBUG']
          
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
            
            puts "  Project directory: #{project_dir}"
            puts "  Source directory config: '#{source_directory}'"
            puts "  Actual source path: #{source_path}"
            
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
              puts "  Checking directory: #{dir_path}" if ENV['DEBUG'] || dir == 'sjui_tools' || dir.include?('node_modules')
              if Dir.exist?(dir_path)
                puts "    Directory exists: #{dir_path}" if dir == 'sjui_tools' || dir.include?('node_modules')
                # Special handling for directories that need ALL files scanned (sjui_tools, node_modules)
                # sjui_tools contains node_modules and other files that should all be excluded
                if dir == 'sjui_tools' || dir == 'node_modules' || dir.include?('node_modules')
                  begin
                    puts "    Scanning all files in #{dir}..."
                    file_count = 0
                    
                    # Use Find module for efficient recursive traversal
                    require 'find'
                    Find.find(dir_path) do |path|
                      # Skip directories
                      next if File.directory?(path)
                      
                      # Get relative path from source directory
                      relative_path = Pathname.new(path).relative_path_from(Pathname.new(source_path)).to_s
                      excluded_files << relative_path
                      file_count += 1
                      
                      # Log first few files and every 100th file for debugging
                      if file_count <= 5 || file_count % 100 == 0
                        puts "      Adding to exclusion: #{relative_path}"
                      end
                    end
                    
                    puts "    Found #{file_count} files in #{dir} (including all subdirectories)"
                  rescue => e
                    puts "    Error scanning #{dir}: #{e.message}"
                    # Fallback to glob if Find fails
                    begin
                      files = Dir.glob("#{dir_path}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }
                      files.each do |file_path|
                        basename = File.basename(file_path)
                        next if basename == '.' || basename == '..'
                        relative_path = Pathname.new(file_path).relative_path_from(Pathname.new(source_path)).to_s
                        excluded_files << relative_path
                      end
                      puts "    Found #{files.size} files in #{dir} (using glob fallback)"
                    rescue => e2
                      puts "    Glob fallback also failed: #{e2.message}"
                    end
                  end
                else
                  # For other directories, use normal glob
                  Dir.glob("#{dir_path}/**/*", File::FNM_DOTMATCH).each do |file_path|
                    next if File.directory?(file_path)
                    # Skip . and .. entries
                    basename = File.basename(file_path)
                    next if basename == '.' || basename == '..'
                    # Get relative path from source directory
                    relative_path = Pathname.new(file_path).relative_path_from(Pathname.new(source_path)).to_s
                    excluded_files << relative_path
                  end
                  puts "  Found #{Dir.glob("#{dir_path}/**/*", File::FNM_DOTMATCH).select{|f| !File.directory?(f)}.size} files in #{dir}"
                end
              else
                puts "    Directory does not exist: #{dir_path}" if dir == 'sjui_tools' || dir.include?('node_modules')
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
              puts "WARNING: No synchronized groups found in project"
              puts "  Main group children: #{project.root_object.main_group.children.map(&:class).join(', ')}"
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
              puts "Info: No exception sets found via xcodeproj gem (this is expected for Xcode 15+)"
              puts "  Using direct file manipulation for synchronized projects..."
              # For Xcode 15+ projects, xcodeproj gem doesn't recognize the new format
              # So we directly manipulate the file
              update_membership_exceptions_directly(excluded_files)
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
            
            # Don't save with xcodeproj yet - let update_membership_exceptions_directly handle everything
            # project.save
            
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
          
          # Count how many times we update
          update_count = 0
          
          # Find and update membershipExceptions
          updated_content = content.gsub(/membershipExceptions\s*=\s*\(([^)]*)\)/m) do |match|
            update_count += 1
            
            # Extract current content between parentheses
            current_content = $1
            
            # Parse existing exceptions
            current_exceptions = []
            unless current_content.strip.empty?
              # Split by comma and newline, clean up each entry
              current_exceptions = current_content.split(/,/).map do |item|
                item.strip.gsub(/^"|"$/, '') # Remove quotes
              end.reject(&:empty?)
            end
            
            puts "  Found existing exceptions: #{current_exceptions.size}"
            if current_exceptions.size > 0
              puts "    Existing: #{current_exceptions.first(3).join(', ')}..." if current_exceptions.any?
            end
            
            # Add our exclusions
            all_exceptions = (current_exceptions + excluded_files).uniq.sort
            
            puts "  Total exceptions after adding: #{all_exceptions.size}"
            
            # Show sample of what's being added
            new_additions = all_exceptions - current_exceptions
            if new_additions.any?
              puts "  Sample of new additions:"
              new_additions.first(10).each do |path|
                puts "    - #{path}"
              end
              if new_additions.size > 10
                puts "    ... and #{new_additions.size - 10} more"
              end
            end
            
            # Format the new exceptions list
            if all_exceptions.empty?
              "membershipExceptions = ("
            else
              formatted_exceptions = all_exceptions.map do |f|
                # Always quote paths for safety
                "\t\t\t\t\"#{f}\""
              end.join(",\n")
              
              "membershipExceptions = (\n#{formatted_exceptions},\n\t\t\t)"
            end
          end
          
          if update_count == 0
            puts "Warning: No membershipExceptions sections found to update"
            puts "  Creating new exception set section for synchronized project..."
            create_exception_set_section(excluded_files)
            return
          end
          
          # Write the updated content back
          File.write(pbxproj_path, updated_content)
          
          puts "✅ Directly updated #{update_count} membershipExceptions section(s) with #{excluded_files.size} exclusions"
        end
        
        def create_exception_set_section(excluded_files)
          # Get pbxproj path
          pbxproj_path = if @project_file_path.end_with?('.pbxproj')
                          @project_file_path
                        elsif @project_file_path.end_with?('.xcodeproj')
                          File.join(@project_file_path, 'project.pbxproj')
                        else
                          Dir.glob(File.join(@project_file_path, '*.xcodeproj', 'project.pbxproj')).first
                        end
          
          unless File.exist?(pbxproj_path)
            puts "Error: Could not find project.pbxproj at #{pbxproj_path}"
            return
          end
          
          puts "Creating exception set section in: #{pbxproj_path}"
          
          # Read the file
          content = File.read(pbxproj_path)
          
          # Get project name from xcodeproj path or config
          xcodeproj_path = pbxproj_path.sub('/project.pbxproj', '')
          project_name = File.basename(xcodeproj_path, '.xcodeproj')
          
          # Try to get project name from config if available
          begin
            config = Core::ConfigManager.load_config
            project_name = config['project_name'] if config['project_name']
          rescue
            # Use the xcodeproj filename if config fails
          end
          
          puts "  Project name: #{project_name}"
          
          # Find the main app target UUID
          target_uuid = nil
          if content =~ /([A-F0-9]{24})\s*\/\*\s*#{Regexp.escape(project_name)}\s*\*\/\s*=\s*\{[^}]*isa\s*=\s*PBXNativeTarget/
            target_uuid = $1
            puts "  Found target UUID: #{target_uuid}"
          else
            # Try alternate patterns
            content.scan(/([A-F0-9]{24})\s*\/\*\s*([^*]+)\s*\*\/\s*=\s*\{[^}]*isa\s*=\s*PBXNativeTarget[^}]*productType\s*=\s*"com\.apple\.product-type\.application"/) do |uuid, name|
              if name.include?(project_name)
                target_uuid = uuid
                puts "  Found target UUID (alt): #{target_uuid} for target: #{name}"
                break
              end
            end
          end
          
          unless target_uuid
            puts "Error: Could not find app target UUID for #{project_name}"
            return
          end
          
          # Find the synchronized root group UUID for the main app folder
          sync_group_uuid = nil
          if content =~ /([A-F0-9]{24})\s*\/\*\s*#{Regexp.escape(project_name)}\s*\*\/\s*=\s*\{[^}]*isa\s*=\s*PBXFileSystemSynchronizedRootGroup/
            sync_group_uuid = $1
            puts "  Found synchronized root group UUID: #{sync_group_uuid}"
          end
          
          unless sync_group_uuid
            puts "Error: Could not find synchronized root group UUID"
            return
          end
          
          # Generate a new UUID for the exception set
          require 'securerandom'
          exception_set_uuid = SecureRandom.hex(12).upcase
          puts "  Generated exception set UUID: #{exception_set_uuid}"
          
          # Format the excluded files
          formatted_exceptions = excluded_files.map do |f|
            "\t\t\t\t\"#{f}\""
          end.join(",\n")
          
          # Create the exception set section
          exception_set_section = <<-SECTION
/* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section */
		#{exception_set_uuid} /* Exceptions for "#{project_name}" folder in "#{project_name}" target */ = {
			isa = PBXFileSystemSynchronizedBuildFileExceptionSet;
			membershipExceptions = (
#{formatted_exceptions},
			);
			target = #{target_uuid} /* #{project_name} */;
		};
/* End PBXFileSystemSynchronizedBuildFileExceptionSet section */
SECTION
          
          # Find where to insert - between PBXFileReference and PBXFileSystemSynchronizedRootGroup
          if content =~ /(\/\*\s*End\s+PBXFileReference\s+section\s*\*\/\s*\n)/
            insertion_point = $1
            # Insert the new section after PBXFileReference section
            content = content.sub(insertion_point, "#{insertion_point}\n#{exception_set_section}\n")
            
            # Now update the synchronized root group to reference the exception set
            # First, find the synchronized root group section
            group_pattern = /(#{Regexp.escape(sync_group_uuid)}\s*\/\*[^*]*\*\/\s*=\s*\{[^}]*?\})/m
            if content =~ group_pattern
              group_content = $1
              
              # Check if there's already an exceptions entry
              if group_content =~ /exceptions\s*=\s*\([^)]*\);/
                # Replace the existing exceptions entry
                updated_group = group_content.gsub(
                  /exceptions\s*=\s*\([^)]*\);/,
                  "exceptions = (\n\t\t\t\t#{exception_set_uuid} /* Exceptions for \"#{project_name}\" folder in \"#{project_name}\" target */,\n\t\t\t);"
                )
              else
                # Add exceptions after isa line
                updated_group = group_content.sub(
                  /(isa\s*=\s*PBXFileSystemSynchronizedRootGroup;)/,
                  "\\1\n\t\t\texceptions = (\n\t\t\t\t#{exception_set_uuid} /* Exceptions for \"#{project_name}\" folder in \"#{project_name}\" target */,\n\t\t\t);"
                )
              end
              
              content = content.sub(group_pattern, updated_group)
            end
            
            # Write the updated content
            File.write(pbxproj_path, content)
            
            puts "✅ Successfully created exception set section with #{excluded_files.size} exclusions"
            puts "  Exception set UUID: #{exception_set_uuid}"
            puts "  Added to synchronized root group: #{sync_group_uuid}"
          else
            puts "Error: Could not find insertion point for exception set section"
          end
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