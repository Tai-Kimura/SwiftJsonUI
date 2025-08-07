# frozen_string_literal: true

require 'xcodeproj'
require_relative 'pbxproj_manager'
require_relative 'config_manager'
require_relative 'xcode_target_helper'

module SjuiTools
  module Core
    class XcodeProjectManager
      attr_reader :project_path, :project
      
      EXCLUDED_PATTERNS = [
        'sjui_tools/',
        'binding_builder/',
        '.git/',
        '.gitignore',
        'README.md',
        'LICENSE',
        'CHANGELOG.md',
        '.DS_Store',
        'Podfile',
        'Podfile.lock',
        'Package.swift',
        'Package.resolved',
        '.swiftpm/',
        'Tests/',
        'UITests/',
        'Docs/',
        'docs/',
        '.github/',
        'VERSION',
        'config/',
        'installer/',
        '.build/',
        'Gemfile',
        'Gemfile.lock',
        '.ruby-version',
        '.gitmodules',
        'node_modules/',
        '.editorconfig',
        '.eslintrc*',
        '.npmignore',
        '.nycrc',
        '.prettierrc*',
        '.babelrc*',
        '.travis.yml',
        '.github/',
        'FUNDING.yml',
        '*.md',
        'LICENSE*',
        '.package-lock.json',
        'node_modules/.*',
        'node_modules/.bin/',
        '**/.*'
      ].freeze

      def initialize(project_path)
        @project_path = project_path
        @project = Xcodeproj::Project.open(project_path)
        @is_synchronized = check_if_synchronized_project
      end
      
      def check_if_synchronized_project
        # Check if the main app target uses synchronized folders
        # (Test targets can still use synchronized folders without issues)
        begin
          project_file = File.join(@project_path, 'project.pbxproj')
          content = File.read(project_file)
          
          # Get the app name from the project
          app_name = File.basename(@project_path, '.xcodeproj')
          
          # Check if the main app has a synchronized root group
          # Look for the main app's synchronized group definition
          main_app_sync_pattern = /#{Regexp.escape(app_name)} \*\/ = \{[^}]*?isa = PBXFileSystemSynchronized(?:Root)?Group/m
          is_sync = content.match?(main_app_sync_pattern)
          
          # Also check if main app target has fileSystemSynchronizedGroups
          if !is_sync && content.include?('fileSystemSynchronizedGroups')
            # Check if the main app target specifically has synchronized groups
            target_pattern = /#{Regexp.escape(app_name)} \*\/ = \{[^}]*?fileSystemSynchronizedGroups = \(/m
            is_sync = content.match?(target_pattern)
          end
          
          if is_sync
            puts "Detected synchronized project (Xcode 15+ format) for main app"
          else
            puts "Detected traditional project format for main app"
          end
          
          return is_sync
        rescue => e
          puts "Warning: Could not determine project type: #{e.message}"
          return false
        end
      end


      def add_file(file_path, group_name)
        # Skip if synchronized project
        if @is_synchronized
          puts "Skipping file addition for synchronized project: #{File.basename(file_path)}"
          return
        end
        
        # Validate file path
        unless File.exist?(file_path)
          puts "Warning: File does not exist: #{file_path}"
          return
        end
        
        # Calculate relative path from project directory first
        project_dir = File.dirname(@project_path)
        begin
          relative_path = Pathname.new(file_path).relative_path_from(Pathname.new(project_dir)).to_s
          
          # Remove app name prefix if present (for files within the app directory)
          app_name = File.basename(@project_path, '.xcodeproj')
          if relative_path.start_with?("#{app_name}/")
            relative_path = relative_path.sub(/^#{Regexp.escape(app_name)}\//, '')
          end
          
          puts "Debug: Relative path: #{relative_path}"
          
          # Validate that the file is within the project directory
          if relative_path.start_with?('..')
            puts "Warning: File is outside project directory: #{file_path}"
            return
          end
          
          # Check if file should be excluded
          excluded = EXCLUDED_PATTERNS.any? do |pattern|
            if pattern.end_with?('/')
              relative_path.start_with?(pattern)
            elsif pattern.include?('*')
              # Handle wildcard patterns
              File.fnmatch?(pattern, File.basename(relative_path)) || File.fnmatch?(pattern, relative_path)
            else
              relative_path == pattern || File.basename(relative_path) == pattern
            end
          end
          
          if excluded
            puts "Excluding file from Xcode project: #{relative_path}"
            return
          end
        rescue ArgumentError => e
          puts "Error calculating relative path: #{e.message}"
          return
        end
        
        # Only create group after validation passes
        group = find_or_create_group(group_name)
        
        # Check if file already exists in project
        file_name = File.basename(file_path)
        puts "Debug: Adding file - basename: #{file_name}, full path: #{file_path}"
        
        existing = group.files.find { |f| f.path == file_name || f.path == relative_path }
        
        if existing
          puts "File already in project: #{file_name}"
          return
        end
        
        # Add file reference with proper relative path
        file_ref = group.new_file(relative_path)
        file_ref.name = file_name
        puts "Debug: File reference name set to: #{file_ref.name}"
        
        # Add to target if it's a source file
        if file_path.end_with?('.swift', '.m', '.mm')
          # アプリターゲットを取得して追加
          app_targets = Core::XcodeTargetHelper.get_app_targets(@project)
          app_targets.each do |target|
            target.add_file_references([file_ref])
          end
        end
        
        # Save project
        @project.save
        puts "Added to Xcode project: #{file_name}"
      rescue => e
        puts "Error adding file to Xcode project: #{e.message}"
      end

      def find_or_create_group(group_name)
        # Skip if synchronized project
        if @is_synchronized
          puts "Skipping group creation for synchronized project: #{group_name}"
          return nil
        end
        
        puts "Debug: find_or_create_group called with: '#{group_name}'"
        # Handle nested groups
        parts = group_name.split('/')
        puts "Debug: Split into parts: #{parts.inspect}"
        
        # Find the proper base group (considering source_directory)
        config = Core::ConfigManager.load_config
        source_directory = config['source_directory'] || ''
        
        current_group = @project.main_group
        
        # If source_directory is empty, try to find the app group
        if source_directory.empty?
          # Look for the main app group (usually has the same name as the project)
          app_name = File.basename(@project_path, '.xcodeproj')
          app_group = current_group.groups.find { |g| g.name == app_name || g.path == app_name }
          if app_group
            current_group = app_group
            puts "Debug: Using app group '#{app_name}' as base"
          else
            puts "Warning: Could not find app group '#{app_name}', using main group"
          end
        else
          # Navigate to source directory group if specified
          source_parts = source_directory.split('/')
          source_parts.each do |part|
            existing = current_group.groups.find { |g| g.name == part || g.path == part }
            if existing
              current_group = existing
              puts "Debug: Found existing group '#{part}'"
            else
              # Check again with display_name
              existing = current_group.groups.find { |g| g.display_name == part }
              if existing
                current_group = existing
                puts "Debug: Found existing group by display_name '#{part}'"
              else
                # If source directory group doesn't exist, create it
                puts "Warning: Creating new group '#{part}' - this might create duplicates!"
                current_group = current_group.new_group(part)
              end
            end
          end
        end
        
        # Now create the requested group structure
        parts.each do |part|
          existing = current_group.groups.find { |g| g.name == part }
          if existing
            current_group = existing
          else
            current_group = current_group.new_group(part)
          end
        end
        
        current_group
      end

      def add_core_files(files)
        core_group = find_or_create_group('Core')
        
        files.each do |file_info|
          file_path = file_info[:path]
          sub_group = file_info[:group]
          
          group = sub_group ? find_or_create_group("Core/#{sub_group}") : core_group
          add_file_to_group(file_path, group)
        end
        
        @project.save
      end

      def add_directory(dir_path, group_name)
        # Skip if synchronized project
        if @is_synchronized
          puts "Skipping directory addition for synchronized project: #{group_name}"
          return
        end
        
        return unless Dir.exist?(dir_path)
        
        # Check if the entire directory should be excluded
        project_dir = File.dirname(@project_path)
        relative_dir_path = Pathname.new(dir_path).relative_path_from(Pathname.new(project_dir)).to_s
        
        if EXCLUDED_PATTERNS.any? { |pattern| pattern.end_with?('/') && relative_dir_path.start_with?(pattern.chomp('/')) }
          puts "Excluding entire directory from Xcode project: #{relative_dir_path}"
          return
        end
        
        group = find_or_create_group(group_name)
        
        Dir.glob(File.join(dir_path, '**', '*.swift')).each do |file|
          relative_path = Pathname.new(file).relative_path_from(Pathname.new(dir_path))
          sub_groups = relative_path.dirname.to_s.split('/')
          
          current_group = group
          sub_groups.each do |sub_group|
            next if sub_group == '.'
            current_group = current_group.groups.find { |g| g.name == sub_group } ||
                          current_group.new_group(sub_group)
          end
          
          add_file_to_group(file, current_group)
        end
        
        @project.save
      end

      def add_binding_files(binding_files, project_dir)
        binding_files.each do |file_path|
          add_file(file_path, 'Bindings')
        end
        
        # Clean up any empty groups that might have been created
        cleanup_empty_groups
      end

      private

      def cleanup_empty_groups
        # Remove empty groups from main group
        remove_empty_groups_recursive(@project.main_group)
        # Also remove any phantom references
        remove_phantom_references
        @project.save
      end
      
      def remove_empty_groups_recursive(group)
        return unless group.groups
        
        groups_to_remove = []
        
        group.groups.each do |subgroup|
          # First, recursively clean subgroups
          remove_empty_groups_recursive(subgroup)
          
          # Check if this group is empty (no files and no subgroups)
          if subgroup.files.empty? && subgroup.groups.empty?
            # Special handling for certain groups we want to keep
            unless ['Products', 'Frameworks'].include?(subgroup.name)
              groups_to_remove << subgroup
              puts "Removing empty group: #{subgroup.name}"
            end
          end
        end
        
        # Remove the empty groups
        groups_to_remove.each do |subgroup|
          subgroup.remove_from_project
        end
      end
      
      def remove_phantom_references
        # Get project directory name
        project_name = File.basename(@project_path, '.xcodeproj')
        
        # Find duplicate project references
        # Look for groups that have the same name as the project and are at the root level
        groups_to_remove = []
        project_groups = @project.main_group.groups.select { |g| g.name == project_name }
        
        # If there are multiple groups with the project name, keep the first one and remove others
        if project_groups.size > 1
          puts "Found #{project_groups.size} groups named '#{project_name}'"
          # Remove all but the first one
          project_groups[1..-1].each do |group|
            puts "Removing duplicate project reference: #{group.name}"
            groups_to_remove << group
          end
        end
        
        # Also remove any phantom patterns
        phantom_patterns = ['sjui_tools', 'binding_builder']
        
        @project.main_group.groups.each do |group|
          if phantom_patterns.include?(group.name) && group.files.empty? && group.groups.empty?
            puts "Removing phantom reference: #{group.name}"
            groups_to_remove << group
          end
        end
        
        # Remove all marked groups
        groups_to_remove.uniq.each do |group|
          group.remove_from_project
        end
      end

      def add_file_to_group(file_path, group)
        # Skip if synchronized project
        if @is_synchronized
          puts "Skipping file-to-group addition for synchronized project: #{File.basename(file_path)}"
          return
        end
        
        file_name = File.basename(file_path)
        existing = group.files.find { |f| f.path == file_name }
        
        unless existing
          # Calculate relative path from project directory
          project_dir = File.dirname(@project_path)
          relative_path = Pathname.new(file_path).relative_path_from(Pathname.new(project_dir)).to_s
          
          # Remove app name prefix if present (for files within the app directory)
          app_name = File.basename(@project_path, '.xcodeproj')
          if relative_path.start_with?("#{app_name}/")
            relative_path = relative_path.sub(/^#{Regexp.escape(app_name)}\//, '')
          end
          
          # Check if file should be excluded
          excluded = EXCLUDED_PATTERNS.any? do |pattern|
            if pattern.end_with?('/')
              relative_path.start_with?(pattern)
            elsif pattern.include?('*')
              # Handle wildcard patterns
              File.fnmatch?(pattern, File.basename(relative_path)) || File.fnmatch?(pattern, relative_path)
            else
              relative_path == pattern || File.basename(relative_path) == pattern
            end
          end
          
          if excluded
            puts "Excluding file from Xcode project: #{relative_path}"
            return
          end
          
          # Create file reference with proper relative path
          file_ref = group.new_file(relative_path)
          file_ref.name = file_name
          
          if file_path.end_with?('.swift', '.m', '.mm')
            # アプリターゲットを取得して追加
            app_targets = Core::XcodeTargetHelper.get_app_targets(@project)
            app_targets.each do |target|
              target.add_file_references([file_ref])
            end
          end
        end
      end
    end
  end
end