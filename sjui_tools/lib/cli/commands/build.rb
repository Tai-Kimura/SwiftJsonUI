# frozen_string_literal: true

require 'optparse'
require_relative '../../core/config_manager'
require_relative '../../core/project_finder'

module SjuiTools
  module CLI
    module Commands
      class Build
        def run(args)
          options = parse_options(args)
          
          # Detect mode
          mode = options[:mode] || Core::ConfigManager.detect_mode
          
          case mode
          when 'binding', 'all'
            build_binding
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
            
            opts.on('--mode MODE', ['all', 'binding', 'swiftui'], 
                    'Build mode (all, binding, swiftui)') do |mode|
              options[:mode] = mode
            end
            
            opts.on('-h', '--help', 'Show this help message') do
              puts opts
              exit
            end
          end.parse!(args)
          
          options
        end

        def build_binding
          puts "Building binding files..."
          
          # Setup project paths
          unless Core::ProjectFinder.setup_paths
            puts "Error: Could not find project file (.xcodeproj or Package.swift)"
            exit 1
          end
          
          # Load custom view types from config
          config = Core::ConfigManager.load_config
          custom_view_types = config['custom_view_types'] || {}
          
          # Setup custom view types
          if custom_view_types.any?
            require_relative '../../binding/json_loader'
            require_relative '../../binding/import_module_manager'
            
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
            Binding::JsonLoader.view_type_set.merge!(view_type_mappings) unless view_type_mappings.empty?
            
            # Add import mappings
            import_mappings.each do |type, module_name|
              Binding::ImportModuleManager.add_type_import_mapping(type, module_name)
            end
          end
          
          # Run JsonLoader
          require_relative '../../binding/json_loader'
          loader = Binding::JsonLoader.new
          loader.start_analyze
        end

        def build_swiftui
          puts "Building SwiftUI files..."
          # TODO: Implement SwiftUI build
          puts "SwiftUI build not yet implemented"
        end
      end
    end
  end
end