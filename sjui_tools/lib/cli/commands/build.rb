# frozen_string_literal: true

require 'optparse'
require_relative '../../core/config_manager'
require_relative '../../core/project_finder'
require_relative '../../core/logger'

module SjuiTools
  module CLI
    module Commands
      class Build
        def run(args)
          options = parse_options(args)
          
          # Detect mode
          mode = options[:mode] || Core::ConfigManager.detect_mode
          
          case mode
          when 'uikit', 'all'
            build_uikit
          end
          
          if mode == 'swiftui' || mode == 'all'
            build_swiftui
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
            
            opts.on('-h', '--help', 'Show this help message') do
              puts opts
              exit
            end
          end.parse!(args)
          
          options
        end

        def build_uikit
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

        def build_swiftui
          Core::Logger.info "Building SwiftUI files..."
          
          # Setup project paths
          unless Core::ProjectFinder.setup_paths
            Core::Logger.error "Could not find project file (.xcodeproj or Package.swift)"
            exit 1
          end
          
          require_relative '../../swiftui/json_to_swiftui_converter'
          require_relative '../../swiftui/view_updater'
          require_relative '../../swiftui/data_model_updater'
          
          config = Core::ConfigManager.load_config
          source_path = Core::ProjectFinder.get_full_source_path || Dir.pwd
          layouts_dir = File.join(source_path, config['layouts_directory'] || 'Layouts')
          view_dir = File.join(source_path, config['view_directory'] || 'View')
          
          # Process all JSON files in Layouts directory
          json_files = Dir.glob(File.join(layouts_dir, '**/*.json'))
          
          if json_files.empty?
            Core::Logger.warn "No JSON files found in #{layouts_dir}"
            return
          end
          
          # First update Data models based on JSON
          data_updater = SjuiTools::SwiftUI::DataModelUpdater.new
          data_updater.update_data_models
          
          converter = SjuiTools::SwiftUI::JsonToSwiftUIConverter.new
          updater = SjuiTools::SwiftUI::ViewUpdater.new
          
          json_files.each do |json_file|
            # Get relative path from layouts directory
            relative_path = Pathname.new(json_file).relative_path_from(Pathname.new(layouts_dir)).to_s
            base_name = File.basename(relative_path, '.json')
            dir_path = File.dirname(relative_path)
            
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
              swiftui_code = converter.convert_json_to_view(json_file)
              
              # Update the existing Swift file's generatedBody
              updater.update_generated_body(swift_file, swiftui_code)
              
              Core::Logger.info "  Updated: #{swift_file}"
            else
              Core::Logger.debug "  Skipping: #{relative_path} (no corresponding Swift file)"
            end
          end
          
          Core::Logger.success "SwiftUI build completed!"
        end
      end
    end
  end
end