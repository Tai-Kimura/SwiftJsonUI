# frozen_string_literal: true

module SjuiTools
  module Core
    class ProjectFinder
      class << self
        attr_accessor :project_dir, :project_file_path, :source_directory

        def find_xcodeproj(starting_dir = Dir.pwd)
          current_dir = File.expand_path(starting_dir)
          
          # Search up to 5 levels up
          5.times do
            xcodeproj = Dir.glob(File.join(current_dir, '*.xcodeproj')).first
            return xcodeproj if xcodeproj
            
            parent = File.dirname(current_dir)
            break if parent == current_dir
            current_dir = parent
          end
          
          nil
        end

        def find_package_swift(starting_dir = Dir.pwd)
          current_dir = File.expand_path(starting_dir)
          
          # Search up to 5 levels up
          5.times do
            package_file = File.join(current_dir, 'Package.swift')
            return package_file if File.exist?(package_file)
            
            parent = File.dirname(current_dir)
            break if parent == current_dir
            current_dir = parent
          end
          
          nil
        end

        def setup_paths(project_file_path = nil)
          # If project file path is provided, use it
          if project_file_path
            @project_file_path = File.expand_path(project_file_path)
            @project_dir = File.dirname(@project_file_path)
            return true
          end
          
          # Otherwise, try to find project file
          xcodeproj = find_xcodeproj
          if xcodeproj
            @project_file_path = xcodeproj
            @project_dir = File.dirname(xcodeproj)
            return true
          end
          
          package_swift = find_package_swift
          if package_swift
            @project_file_path = package_swift
            @project_dir = File.dirname(package_swift)
            return true
          end
          
          # Fallback to current directory
          @project_dir = Dir.pwd
          @project_file_path = nil
          false
        end

        def find_source_directory
          return @source_directory if @source_directory
          
          # Common source directory names
          common_names = ['Sources', 'Source', 'src', File.basename(@project_dir)]
          
          common_names.each do |name|
            path = File.join(@project_dir, name)
            if Dir.exist?(path)
              @source_directory = name
              return name
            end
          end
          
          # If not found, use empty string (project root)
          @source_directory = ''
        end

        def get_full_source_path
          source_dir = find_source_directory
          if source_dir.empty?
            @project_dir
          else
            File.join(@project_dir, source_dir)
          end
        end

        # Find directory by name within project
        def find_directory(name, create: false)
          # First check in source directory
          source_path = get_full_source_path
          dir_path = File.join(source_path, name)
          
          if Dir.exist?(dir_path)
            return dir_path
          elsif create
            FileUtils.mkdir_p(dir_path)
            return dir_path
          end
          
          # Then check project root
          dir_path = File.join(@project_dir, name)
          if Dir.exist?(dir_path)
            return dir_path
          elsif create
            FileUtils.mkdir_p(dir_path)
            return dir_path
          end
          
          nil
        end

        # Reset paths (useful for testing)
        def reset!
          @project_dir = nil
          @project_file_path = nil
          @source_directory = nil
        end
      end
    end
  end
end