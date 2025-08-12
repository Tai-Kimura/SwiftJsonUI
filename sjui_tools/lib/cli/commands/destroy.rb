# frozen_string_literal: true

require_relative '../command_base'
require_relative '../../core/config_manager'
require_relative '../../core/logger'
require 'fileutils'
require 'pathname'

module SjuiTools
  module CLI
    module Commands
      class Destroy < CommandBase
        def run(args)
          if args.empty? || args[0] == '--help' || args[0] == '-h'
            show_help
            return
          end
          
          # Check for --force option
          force = false
          if args.include?('--force') || args.include?('-f')
            force = true
            args.delete('--force')
            args.delete('-f')
          end
          
          type = args.shift
          name = args.shift
          
          if name.nil?
            puts "Error: Please specify a name"
            show_help
            exit 1
          end
          
          # Detect mode
          mode = Core::ConfigManager.detect_mode
          
          case type
          when 'view', 'partial', 'collection'
            if mode == 'swiftui'
              destroy_swiftui_view(type, name, force)
            else
              destroy_view(type, name, force)
            end
          when 'uikit_binding'
            destroy_binding(name, force)
          else
            Core::Logger.error "Unknown type '#{type}'"
            show_help
            exit 1
          end
        end
        
        private
        
        def destroy_swiftui_view(type, name, force = false)
          config = Core::ConfigManager.load_config
          
          # Get paths from config
          layouts_dir = config['layouts_directory'] || 'Layouts'
          view_dir = config['view_directory'] || 'View'
          viewmodel_dir = config['viewmodel_directory'] || 'ViewModel'
          data_dir = config['data_directory'] || 'Data'
          source_directory = config['source_directory'] || ''
          
          # Setup paths
          project_root = find_project_root
          
          if source_directory.empty?
            base_path = project_root
          else
            base_path = File.join(project_root, source_directory)
          end
          
          # Parse name (could be nested like "home/dashboard")
          name_parts = name.split('/')
          file_name = name_parts.last
          
          # Convert names
          view_class_name = file_name.split(/[_\-]/).map(&:capitalize).join
          json_file_name = file_name.gsub(/([A-Z])/, '_\1').downcase.gsub(/^_/, '').gsub(/-/, '_')
          
          # Paths to delete
          files_to_delete = []
          
          # JSON file path
          json_path = if name_parts.length > 1
            File.join(base_path, layouts_dir, *name_parts[0..-2], "#{json_file_name}.json")
          else
            File.join(base_path, layouts_dir, "#{json_file_name}.json")
          end
          files_to_delete << json_path if File.exist?(json_path)
          
          # Swift View folder path (new structure - folder contains all view files)
          swift_folder_path = if name_parts.length > 1
            File.join(base_path, view_dir, *name_parts[0..-2], view_class_name)
          else
            File.join(base_path, view_dir, view_class_name)
          end
          
          # Check if folder exists (new structure)
          if Dir.exist?(swift_folder_path)
            # Add all files in the folder to delete list
            Dir.glob(File.join(swift_folder_path, '**/*')).each do |file|
              files_to_delete << file if File.file?(file)
            end
            # Mark folder itself for deletion
            files_to_delete << swift_folder_path
          else
            # Fallback to old structure (single file)
            swift_file_name = "#{view_class_name}View.swift"
            swift_path = if name_parts.length > 1
              File.join(base_path, view_dir, *name_parts[0..-2], swift_file_name)
            else
              File.join(base_path, view_dir, swift_file_name)
            end
            files_to_delete << swift_path if File.exist?(swift_path)
          end
          
          # ViewModel file path
          viewmodel_file_name = "#{view_class_name}ViewModel.swift"
          viewmodel_path = if name_parts.length > 1
            File.join(base_path, viewmodel_dir, *name_parts[0..-2], viewmodel_file_name)
          else
            File.join(base_path, viewmodel_dir, viewmodel_file_name)
          end
          files_to_delete << viewmodel_path if File.exist?(viewmodel_path)
          
          # Data file path
          data_file_name = "#{view_class_name}Data.swift"
          data_path = if name_parts.length > 1
            File.join(base_path, data_dir, *name_parts[0..-2], data_file_name)
          else
            File.join(base_path, data_dir, data_file_name)
          end
          files_to_delete << data_path if File.exist?(data_path)
          
          # Check if we found any files
          if files_to_delete.empty?
            Core::Logger.warn "No files found to delete for #{type} '#{name}'"
            return
          end
          
          # Confirm deletion
          Core::Logger.info "The following files will be deleted:"
          puts
          
          files_to_delete.each do |file|
            puts "  📄 #{file}"
          end
          
          unless force
            puts
            print "Are you sure you want to delete these files? (y/N): "
            
            begin
              confirmation = STDIN.gets.chomp.downcase
            rescue
              Core::Logger.error "Cannot read input. Use --force flag to skip confirmation."
              return
            end
            
            unless confirmation == 'y' || confirmation == 'yes'
              Core::Logger.info "Cancelled"
              return
            end
          end
          
          # Delete files and folders
          files_to_delete.each do |file|
            if File.directory?(file)
              FileUtils.rm_rf(file)
              Core::Logger.info "Deleted folder: #{file}"
            else
              FileUtils.rm_f(file)
              Core::Logger.info "Deleted: #{file}"
            end
          end
          
          Core::Logger.info ""
          Core::Logger.info "✅ Successfully destroyed #{type} '#{name}'"
        end
        
        def destroy_view(type, name)
          config = Core::ConfigManager.load_config
          
          # Get paths from config
          layouts_path = config['layouts_path'] || 'Layouts'
          source_directory = config['source_directory'] || ''
          
          # Setup paths
          project_root = find_project_root
          
          if source_directory.empty?
            base_path = project_root
            view_base_path = File.join(project_root, 'View')
          else
            base_path = File.join(project_root, source_directory)
            view_base_path = File.join(base_path, 'View')
          end
          
          layouts_base_path = File.join(base_path, layouts_path)
          bindings_base_path = File.join(base_path, 'Bindings')
          
          # Parse name (could be nested like "home/dashboard")
          name_parts = name.split('/')
          file_name = name_parts.last
          
          # Capitalize properly for Swift class names
          class_name = file_name.split('_').map(&:capitalize).join
          
          # Paths to delete
          files_to_delete = []
          dirs_to_delete = []
          
          # JSON file
          json_path = if name_parts.length > 1
            File.join(layouts_base_path, *name_parts[0..-2], "#{file_name}.json")
          else
            File.join(layouts_base_path, "#{file_name}.json")
          end
          files_to_delete << json_path if File.exist?(json_path)
          
          # Binding file
          binding_file = "#{class_name}Binding.swift"
          binding_path = File.join(bindings_base_path, binding_file)
          files_to_delete << binding_path if File.exist?(binding_path)
          
          # ViewController and related files (for views, not partials)
          if type == 'view' || type == 'collection'
            view_controller_name = "#{class_name}ViewController.swift"
            
            # Check if it's in a folder
            if name_parts.length > 1
              view_folder = File.join(view_base_path, *name_parts[0..-2], class_name)
            else
              view_folder = File.join(view_base_path, class_name)
            end
            
            if Dir.exist?(view_folder)
              # If folder exists, mark it for deletion
              dirs_to_delete << view_folder
              
              # List all files in the folder
              Dir.glob(File.join(view_folder, '**/*')).each do |file|
                puts "  Will delete: #{file}" if File.file?(file)
              end
            else
              # Try to find individual ViewController file
              view_controller_path = File.join(view_base_path, view_controller_name)
              files_to_delete << view_controller_path if File.exist?(view_controller_path)
            end
            
            # For collection views, check for cell files
            if type == 'collection'
              cell_file = "#{class_name}CollectionViewCell.swift"
              cell_path = File.join(view_base_path, class_name, cell_file)
              files_to_delete << cell_path if File.exist?(cell_path)
              
              # Cell binding
              cell_binding_file = "#{class_name}CellBinding.swift"
              cell_binding_path = File.join(bindings_base_path, cell_binding_file)
              files_to_delete << cell_binding_path if File.exist?(cell_binding_path)
              
              # Cell JSON
              cell_json = "#{file_name}_cell.json"
              cell_json_path = if name_parts.length > 1
                File.join(layouts_base_path, *name_parts[0..-2], cell_json)
              else
                File.join(layouts_base_path, cell_json)
              end
              files_to_delete << cell_json_path if File.exist?(cell_json_path)
            end
          end
          
          # Confirm deletion
          if files_to_delete.empty? && dirs_to_delete.empty?
            puts "No files found to delete for #{type} '#{name}'"
            return
          end
          
          puts "The following files/directories will be deleted:"
          puts
          
          files_to_delete.each do |file|
            puts "  📄 #{file}"
          end
          
          dirs_to_delete.each do |dir|
            puts "  📁 #{dir}/"
          end
          
          puts
          print "Are you sure you want to delete these files? (y/N): "
          confirmation = STDIN.gets.chomp.downcase
          
          unless confirmation == 'y' || confirmation == 'yes'
            puts "Cancelled"
            return
          end
          
          # Delete files
          files_to_delete.each do |file|
            FileUtils.rm_f(file)
            puts "Deleted: #{file}"
          end
          
          # Delete directories
          dirs_to_delete.each do |dir|
            FileUtils.rm_rf(dir)
            puts "Deleted directory: #{dir}"
          end
          
          # Update Xcode project if needed
          update_xcode_project(files_to_delete + dirs_to_delete)
          
          puts
          puts "✅ Successfully destroyed #{type} '#{name}'"
        end
        
        def destroy_binding(name)
          config = Core::ConfigManager.load_config
          
          # Get paths from config
          source_directory = config['source_directory'] || ''
          
          # Setup paths
          project_root = find_project_root
          
          if source_directory.empty?
            base_path = project_root
          else
            base_path = File.join(project_root, source_directory)
          end
          
          bindings_base_path = File.join(base_path, 'Bindings')
          
          # Capitalize properly for Swift class names
          class_name = name.split('_').map(&:capitalize).join
          binding_file = "#{class_name}Binding.swift"
          binding_path = File.join(bindings_base_path, binding_file)
          
          unless File.exist?(binding_path)
            puts "Binding file not found: #{binding_path}"
            return
          end
          
          puts "The following file will be deleted:"
          puts "  📄 #{binding_path}"
          puts
          print "Are you sure you want to delete this file? (y/N): "
          confirmation = STDIN.gets.chomp.downcase
          
          unless confirmation == 'y' || confirmation == 'yes'
            puts "Cancelled"
            return
          end
          
          FileUtils.rm_f(binding_path)
          puts "Deleted: #{binding_path}"
          
          # Update Xcode project
          update_xcode_project([binding_path])
          
          puts "✅ Successfully destroyed binding '#{name}'"
        end
        
        def update_xcode_project(deleted_paths)
          # Try to update Xcode project if xcodeproj is available
          begin
            require 'xcodeproj'
            
            # Find xcodeproj file
            xcodeproj_files = Dir.glob('*.xcodeproj')
            return if xcodeproj_files.empty?
            
            project = Xcodeproj::Project.open(xcodeproj_files.first)
            
            deleted_paths.each do |path|
              # Find and remove file reference
              file_ref = project.files.find { |f| f.real_path.to_s == path }
              if file_ref
                file_ref.remove_from_project
                puts "Removed from Xcode project: #{File.basename(path)}"
              end
            end
            
            project.save
          rescue LoadError
            # xcodeproj gem not available, skip
          rescue => e
            puts "Warning: Could not update Xcode project: #{e.message}"
          end
        end
        
        def find_project_root
          current = Dir.pwd
          
          # Look for sjui.yml or xcodeproj to identify project root
          while current != '/'
            if File.exist?(File.join(current, 'sjui.yml')) || 
               !Dir.glob(File.join(current, '*.xcodeproj')).empty?
              return current
            end
            current = File.dirname(current)
          end
          
          # Default to current directory
          Dir.pwd
        end
        
        def show_help
          puts "Usage: sjui destroy TYPE NAME"
          puts
          puts "Types:"
          puts "  view       - Destroy a view (ViewController, JSON, and Binding)"
          puts "  partial    - Destroy a partial view (JSON and Binding)"
          puts "  collection - Destroy a collection view (ViewController, Cell, JSONs, and Bindings)"
          puts "  binding    - Destroy only a binding file"
          puts
          puts "Examples:"
          puts "  sjui destroy view splash"
          puts "  sjui destroy view home/dashboard"
          puts "  sjui destroy partial header"
          puts "  sjui destroy collection product_list"
          puts "  sjui destroy binding custom"
          puts
          puts "Note: This will permanently delete files. A confirmation will be required."
        end
      end
    end
  end
end