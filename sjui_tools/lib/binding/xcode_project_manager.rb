# frozen_string_literal: true

require 'xcodeproj'
require_relative '../core/xcodeproj_patch'
require_relative 'xcode_project/pbxproj_manager'
require_relative '../core/config_manager'

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
        existing = group.files.find { |f| f.path == file_name }
        
        if existing
          puts "File already in project: #{file_name}"
          return
        end
        
        # Add file reference
        file_ref = group.new_file(file_path)
        
        # Add to target if it's a source file
        if file_path.end_with?('.swift', '.m', '.mm')
          main_target = @project.targets.first
          main_target.add_file_references([file_ref]) if main_target
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
        current_group = @project.main_group
        
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

      private

      def add_file_to_group(file_path, group)
        file_name = File.basename(file_path)
        existing = group.files.find { |f| f.path == file_name }
        
        unless existing
          file_ref = group.new_file(file_path)
          
          if file_path.end_with?('.swift', '.m', '.mm')
            main_target = @project.targets.first
            main_target.add_file_references([file_ref]) if main_target
          end
        end
      end

      def add_binding_files(binding_files, project_dir)
        binding_files.each do |file_path|
          add_file(file_path, 'Bindings')
        end
      end

      # Legacy method support for migration
      def self.add_view_controller_to_project(project_path, view_name, parent_dir, is_root = false)
        manager = new(project_path)
        
        # Construct file paths
        view_dir = File.join(parent_dir, Core::ConfigManager.get_view_directory)
        file_path = File.join(view_dir, "#{view_name}ViewController.swift")
        
        manager.add_file(file_path, 'View')
      end

      def self.add_json_to_project(project_path, json_name, parent_dir)
        manager = new(project_path)
        
        layouts_dir = File.join(parent_dir, Core::ConfigManager.get_layouts_directory)
        file_path = File.join(layouts_dir, "#{json_name}.json")
        
        manager.add_file(file_path, 'Layouts')
      end

      def self.add_binding_to_project(project_path, binding_name, parent_dir)
        manager = new(project_path)
        
        bindings_dir = File.join(parent_dir, Core::ConfigManager.get_bindings_directory)
        file_path = File.join(bindings_dir, "#{binding_name}Binding.swift")
        
        manager.add_file(file_path, 'Bindings')
      end
    end
  end
end