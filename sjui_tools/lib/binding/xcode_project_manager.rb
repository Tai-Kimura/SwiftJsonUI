# frozen_string_literal: true

require 'xcodeproj'
# require_relative '../core/xcodeproj_patch' # xcodeproj 1.27.0 has native Xcode 16 support
require_relative 'xcode_project/pbxproj_manager'
require_relative '../core/config_manager'
require_relative '../core/xcode_target_helper'

module SjuiTools
  module Binding
    class XcodeProjectManager
      attr_reader :project_path, :project

      def initialize(project_path)
        @project_path = project_path
        @project = Xcodeproj::Project.open(project_path)
      end


      def add_file(file_path, group_name)
        # Find or create group
        group = find_or_create_group(group_name)
        
        # Check if file already exists in project
        file_name = File.basename(file_path)
        puts "Debug: Adding file - basename: #{file_name}, full path: #{file_path}"
        
        existing = group.files.find { |f| f.path == file_name }
        
        if existing
          puts "File already in project: #{file_name}"
          return
        end
        
        # Calculate relative path from project directory
        project_dir = File.dirname(@project_path)
        relative_path = Pathname.new(file_path).relative_path_from(Pathname.new(project_dir)).to_s
        puts "Debug: Relative path: #{relative_path}"
        
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
        # Handle nested groups
        parts = group_name.split('/')
        
        # Find the proper base group (considering source_directory)
        config = Core::ConfigManager.load_config
        source_directory = config['source_directory'] || ''
        
        current_group = @project.main_group
        
        # Navigate to source directory group if specified
        unless source_directory.empty?
          source_parts = source_directory.split('/')
          source_parts.each do |part|
            existing = current_group.groups.find { |g| g.name == part }
            if existing
              current_group = existing
            else
              # If source directory group doesn't exist, create it
              current_group = current_group.new_group(part)
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
        return unless Dir.exist?(dir_path)
        
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
      end

      private

      def add_file_to_group(file_path, group)
        file_name = File.basename(file_path)
        existing = group.files.find { |f| f.path == file_name }
        
        unless existing
          # Calculate relative path from project directory
          project_dir = File.dirname(@project_path)
          relative_path = Pathname.new(file_path).relative_path_from(Pathname.new(project_dir)).to_s
          
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