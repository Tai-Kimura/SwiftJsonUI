# frozen_string_literal: true

require 'optparse'
require_relative '../../core/config_manager'
require_relative '../../core/project_finder'
require_relative '../../core/logger'
require_relative '../../core/resources_manager'

module SjuiTools
  module CLI
    module Commands
      class Build
        def run(args)
          options = parse_options(args)
          
          # Detect mode
          mode = options[:mode] || Core::ConfigManager.detect_mode
          
          # Process all JSON files for string extraction
          process_strings_extraction
          
          case mode
          when 'uikit', 'all'
            build_uikit(options)
          end
          
          if mode == 'swiftui' || mode == 'all'
            build_swiftui(options)
          end
        end

        private

        def parse_options(args)
          options = {}
          
          OptionParser.new do |opts|
            opts.banner = "Usage: sjui build [options]"
            
            opts.on('--mode MODE', ['all', 'uikit', 'swiftui'], 
                    'Build mode (all, uikit, swiftui)') do |mode|
              options[:mode] = mode
            end
            
            opts.on('--clean', 'Clean cache before building') do
              options[:clean] = true
            end
            
            opts.on('-h', '--help', 'Show this help message') do
              puts opts
              exit
            end
          end.parse!(args)
          
          options
        end

        def build_uikit(options = {})
          Core::Logger.info "Building UIKit files..."
          
          # Setup project paths
          unless Core::ProjectFinder.setup_paths
            Core::Logger.error "Could not find project file (.xcodeproj or Package.swift)"
            exit 1
          end
          
          # Load custom view types from config
          config = Core::ConfigManager.load_config
          custom_view_types = config['custom_view_types'] || {}
          
          # Setup custom view types
          if custom_view_types.any?
            require_relative '../../uikit/json_loader'
            require_relative '../../uikit/import_module_manager'
            
            view_type_mappings = {}
            import_mappings = {}
            
            custom_view_types.each do |view_type, type_config|
              if type_config['class_name']
                view_type_mappings[view_type.to_sym] = type_config['class_name']
              end
              if type_config['import_module']
                import_mappings[view_type] = type_config['import_module']
              end
            end
            
            # Extend view type set
            UIKit::JsonLoader.view_type_set.merge!(view_type_mappings) unless view_type_mappings.empty?
            
            # Add import mappings
            import_mappings.each do |type, module_name|
              UIKit::ImportModuleManager.add_type_import_mapping(type, module_name)
            end
          end
          
          # Run JsonLoader
          require_relative '../../uikit/json_loader'
          loader = UIKit::JsonLoader.new
          loader.start_analyze
        end

        def build_swiftui(options = {})
          Core::Logger.info "Building SwiftUI files..."
          
          # Setup project paths
          unless Core::ProjectFinder.setup_paths
            Core::Logger.error "Could not find project file (.xcodeproj or Package.swift)"
            exit 1
          end
          
          require_relative '../../swiftui/json_to_swiftui_converter'
          require_relative '../../swiftui/view_updater'
          require_relative '../../swiftui/data_model_updater'
          require_relative '../../swiftui/build_cache_manager'
          
          config = Core::ConfigManager.load_config
          source_path = Core::ProjectFinder.get_full_source_path || Dir.pwd
          layouts_dir = File.join(source_path, config['layouts_directory'] || 'Layouts')
          view_dir = File.join(source_path, config['view_directory'] || 'View')
          
          # Initialize cache manager
          cache_manager = SjuiTools::SwiftUI::BuildCacheManager.new(source_path)
          
          # Clean cache if --clean option is specified
          if options[:clean]
            Core::Logger.info "Cleaning build cache..."
            cache_manager.clean_cache
          end
          last_updated = cache_manager.load_last_updated
          last_including_files = cache_manager.load_last_including_files
          style_dependencies = cache_manager.load_style_dependencies
          
          # Process all JSON files in Layouts directory
          json_files = Dir.glob(File.join(layouts_dir, '**/*.json')).reject do |file|
            # Skip Resources folder
            file.include?(File.join(layouts_dir, 'Resources'))
          end
          
          if json_files.empty?
            Core::Logger.warn "No JSON files found in #{layouts_dir}"
            return
          end
          
          # Track new includes and style dependencies
          new_including_files = {}
          new_style_dependencies = {}
          
          # Filter files that need update
          files_to_update = []
          json_files.each do |json_file|
            file_name = File.basename(json_file, '.json')
            
            # Check if file needs update
            if cache_manager.needs_update?(json_file, last_updated, layouts_dir, last_including_files, style_dependencies)
              files_to_update << json_file
            else
              # Keep existing includes and style dependencies for unchanged files
              new_including_files[file_name] = last_including_files[file_name] if last_including_files[file_name]
              new_style_dependencies[file_name] = style_dependencies[file_name] if style_dependencies[file_name]
            end
          end
          
          # Update Data models if any files need updating
          if files_to_update.any?
            Core::Logger.info "Updating #{files_to_update.length} of #{json_files.length} files..."
            data_updater = SjuiTools::SwiftUI::DataModelUpdater.new
            data_updater.update_data_models
          else
            Core::Logger.info "No files need updating (all cached)"
            return
          end
          
          converter = SjuiTools::SwiftUI::JsonToSwiftUIConverter.new
          updater = SjuiTools::SwiftUI::ViewUpdater.new
          
          files_to_update.each do |json_file|
            # Get relative path from layouts directory
            relative_path = Pathname.new(json_file).relative_path_from(Pathname.new(layouts_dir)).to_s
            base_name = File.basename(relative_path, '.json')
            file_name = File.basename(json_file, '.json')
            dir_path = File.dirname(relative_path)
            
            # Read and parse JSON to extract includes and styles
            begin
              json_content = File.read(json_file)
              json_data = JSON.parse(json_content)
              
              # Extract includes and styles for cache tracking
              includes = cache_manager.extract_includes(json_data)
              styles = cache_manager.extract_styles(json_data)
              
              new_including_files[file_name] = includes if includes.any?
              new_style_dependencies[file_name] = styles if styles.any?
            rescue => ex
              Core::Logger.warn "Failed to parse #{json_file}: #{ex.message}"
            end
            
            # Convert to PascalCase for Swift file
            view_name = base_name.split(/[_\-]/).map(&:capitalize).join
            
            # Determine Swift file path - now targeting GeneratedView in view folder
            swift_file = if dir_path == '.'
              File.join(view_dir, view_name, "#{view_name}GeneratedView.swift")
            else
              File.join(view_dir, dir_path, view_name, "#{view_name}GeneratedView.swift")
            end
            
            if File.exist?(swift_file)
              Core::Logger.info "Processing: #{relative_path}"
              
              # Convert JSON to SwiftUI code
              swiftui_code, _ = converter.convert_json_to_view(json_file)
              
              # Update the existing Swift file's generatedBody
              updater.update_generated_body(swift_file, swiftui_code)
              
              Core::Logger.info "  Updated: #{swift_file}"
            else
              Core::Logger.debug "  Skipping: #{relative_path} (no corresponding Swift file)"
            end
          end
          
          # Save cache for next build
          cache_manager.save_cache(new_including_files, new_style_dependencies)
          
          Core::Logger.success "SwiftUI build completed!"
        end

        def process_strings_extraction
          # Setup project paths
          unless Core::ProjectFinder.setup_paths
            Core::Logger.error "Could not find project file"
            return
          end
          
          config = Core::ConfigManager.load_config
          source_path = Core::ProjectFinder.get_full_source_path || Dir.pwd
          layouts_dir = File.join(source_path, config['layouts_directory'] || 'Layouts')
          
          # Load cache to check for modified files
          cache_dir = File.join(source_path, '.sjui_cache')
          
          # For SwiftUI mode, use swiftui_last_updated.txt
          if config['mode'] == 'swiftui'
            last_updated_file = File.join(cache_dir, 'swiftui_last_updated.txt')
            last_updated = {}
            
            if File.exist?(last_updated_file)
              File.readlines(last_updated_file).each do |line|
                parts = line.strip.split(':', 2)
                if parts.length == 2
                  last_updated[parts[0]] = parts[1].to_i
                end
              end
            end
          else
            # For UIKit mode, use last_updated.json
            last_updated_file = File.join(cache_dir, 'last_updated.json')
            last_updated = {}
            
            if File.exist?(last_updated_file)
              begin
                last_updated = JSON.parse(File.read(last_updated_file))
              rescue JSON::ParserError
                Core::Logger.warn "Failed to parse cache file, processing all files"
              end
            end
          end
          
          # Process all resources through ResourcesManager
          resources_manager = Core::ResourcesManager.new
          resources_manager.process_resources(layouts_dir, last_updated)
        end
      end
    end
  end
end