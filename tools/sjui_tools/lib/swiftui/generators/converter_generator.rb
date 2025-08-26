# frozen_string_literal: true

require 'fileutils'
require 'json'
require_relative '../../core/logger'
require_relative 'swift_component_generator'
require_relative 'adapter_generator'

module SjuiTools
  module SwiftUI
    module Generators
      class ConverterGenerator
        def initialize(name, options = {})
          @name = name
          # Keep original PascalCase name for component, add Converter suffix for class
          @component_pascal_case = name  # e.g., MyTestCard
          @class_name = name + "Converter"  # e.g., MyTestCardConverter
          @options = options
          @logger = Core::Logger
        end

        def generate
          @logger.info "Generating custom converter: #{@class_name}"
          
          # Create converter file
          create_converter_file
          
          # Update mappings file
          update_mappings_file
          
          # Create Swift file using separate generator
          swift_generator = SwiftComponentGenerator.new(@name, @options)
          swift_generator.generate
          
          # Generate adapter file if adapter_directory is configured
          adapter_generator = AdapterGenerator.new(@name, @options)
          adapter_generator.generate
          
          @logger.success "Successfully generated converter: #{@class_name}"
          @logger.info "Converter file created at: views/extensions/#{@name}_converter.rb"
          @logger.info "Mappings file updated with '#{@component_pascal_case}' => '#{@class_name}'"
          
          # Update membership exceptions to exclude the extensions directory
          update_membership_exceptions_if_needed
        end

        private

        def create_converter_file
          # Ensure views/extensions directory exists
          # Check if we're in a test app or main SwiftJsonUI
          if File.exist?(File.join(Dir.pwd, 'sjui_tools'))
            # Test app structure
            extensions_dir = File.join(Dir.pwd, 'sjui_tools', 'lib', 'swiftui', 'views', 'extensions')
          else
            # Main SwiftJsonUI structure
            extensions_dir = File.join(Dir.pwd, 'tools', 'sjui_tools', 'lib', 'swiftui', 'views', 'extensions')
          end
          FileUtils.mkdir_p(extensions_dir)
          
          # Convert name to snake_case for file name
          snake_case_name = @name.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
                                  gsub(/([a-z\d])([A-Z])/,'\1_\2').
                                  downcase
          file_path = File.join(extensions_dir, "#{snake_case_name}_converter.rb")
          
          if File.exist?(file_path)
            @logger.warn "Converter file already exists: #{file_path}"
            print "Overwrite? (y/n): "
            response = gets.chomp.downcase
            return unless response == 'y'
          end
          
          File.write(file_path, converter_template)
          @logger.info "Created converter file: #{file_path}"
        end
        
        def update_mappings_file
          # Check if we're in a test app or main SwiftJsonUI
          if File.exist?(File.join(Dir.pwd, 'sjui_tools'))
            # Test app structure
            mappings_file = File.join(Dir.pwd, 'sjui_tools', 'lib', 'swiftui', 'views', 'extensions', 'converter_mappings.rb')
          else
            # Main SwiftJsonUI structure
            mappings_file = File.join(Dir.pwd, 'tools', 'sjui_tools', 'lib', 'swiftui', 'views', 'extensions', 'converter_mappings.rb')
          end
          
          # Create new mappings file if it doesn't exist
          if !File.exist?(mappings_file)
            create_initial_mappings_file
            return
          end
          
          # Read existing mappings
          content = File.read(mappings_file)
          
          # Check if mapping already exists
          component_type = @component_pascal_case
          if content.include?("'#{component_type}' =>")
            @logger.warn "Mapping for '#{component_type}' already exists in converter_mappings.rb"
            return
          end
          
          # Add new mapping
          new_mapping = "          '#{component_type}' => '#{@class_name}',"
          
          # Insert the new mapping before the closing brace of CONVERTER_MAPPINGS
          content.sub!(/(CONVERTER_MAPPINGS = \{.*?)(,?)(\s*)(        \}\.freeze)/m) do
            existing_mappings = $1
            last_comma = $2
            whitespace = $3
            closing = $4
            
            # If there are existing mappings, add the new one with proper formatting
            if existing_mappings =~ /=>/
              # Ensure the last existing mapping has a comma, then add the new mapping
              "#{existing_mappings},\n#{new_mapping}\n#{closing}"
            else
              # First mapping
              "#{existing_mappings}\n#{new_mapping}\n#{closing}"
            end
          end
          
          File.write(mappings_file, content)
          @logger.info "Updated converter_mappings.rb with new mapping"
        end
        
        def create_initial_mappings_file
          # Ensure views/extensions directory exists
          # Check if we're in a test app or main SwiftJsonUI
          if File.exist?(File.join(Dir.pwd, 'sjui_tools'))
            # Test app structure
            extensions_dir = File.join(Dir.pwd, 'sjui_tools', 'lib', 'swiftui', 'views', 'extensions')
          else
            # Main SwiftJsonUI structure
            extensions_dir = File.join(Dir.pwd, 'tools', 'sjui_tools', 'lib', 'swiftui', 'views', 'extensions')
          end
          FileUtils.mkdir_p(extensions_dir)
          
          mappings_file = File.join(extensions_dir, 'converter_mappings.rb')
          
          content = <<~RUBY
            # frozen_string_literal: true
            
            # This file maps custom component types to their converter classes
            # Auto-generated by sjui g converter command
            
            module SjuiTools
              module SwiftUI
                module Views
                  module Extensions
                    CONVERTER_MAPPINGS = {
                      '#{@component_pascal_case}' => '#{@class_name}',
                    }.freeze
                  end
                end
              end
            end
          RUBY
          
          File.write(mappings_file, content)
          @logger.info "Created converter_mappings.rb with initial mapping"
        end

        def converter_template
          <<~RUBY
            # frozen_string_literal: true
            
            require_relative '../base_view_converter'
            
            module SjuiTools
              module SwiftUI
                module Views
                  module Extensions
                    class #{@class_name} < BaseViewConverter
                      def initialize(component, indent_level = 0, action_manager = nil, converter_factory = nil, view_registry = nil, binding_registry = nil)
                        super(component, indent_level, action_manager, binding_registry)
                        @factory = converter_factory
                        @registry = view_registry
                      end
                      
                      def convert
            #{generate_container_check}
                        
                        # Collect parameters
                        params = []
            #{generate_parameter_collection}
                        
                        if is_container
                          # Container component with children
                          if params.empty?
                            add_line "#{@component_pascal_case} {"
                          else
                            add_line "#{@component_pascal_case}("
                            indent do
                              params.each_with_index do |param, index|
                                if index == params.length - 1
                                  add_line param
                                else
                                  add_line "\#{param},"
                                end
                              end
                            end
                            add_line ") {"
                          end
                          
                          # Process children
                          indent do
                            process_children
                          end
                          
                          add_line "}"
                        else
                          # Non-container component
                          if params.empty?
                            add_line "#{@component_pascal_case}()"
                          else
                            add_line "#{@component_pascal_case}("
                            indent do
                              params.each_with_index do |param, index|
                                if index == params.length - 1
                                  add_line param
                                else
                                  add_line "\#{param},"
                                end
                              end
                            end
                            add_line ")"
                          end
                        end
                        
            #{generate_modifiers_code}
                        
                        generated_code
                      end
                      
                      private
                      
                      def component_name
                        "#{@component_pascal_case}"
                      end
                      
                      # Process children components (handles both 'children' and 'child' keys)
                      def process_children
                        # Handle both 'children' and 'child' keys (both are arrays)
                        child_array = @component['children'] || @component['child']
                        
                        if child_array && child_array.is_a?(Array)
                          child_array.each do |child|
                            child_converter = @factory.create_converter(child, @indent_level, @action_manager, @factory, @registry)
                            @generated_code.concat(child_converter.convert.split("\\n"))
                          end
                        end
                      end
                      
                      # Helper method to format value based on type
                      def format_value(value, type)
                        return nil unless value
                        
                        # Check if it's a binding expression @{propertyName}
                        if value.is_a?(String) && value.start_with?('@{') && value.end_with?('}')
                          # Extract property name and return as binding
                          property_name = value[2..-2]  # Remove @{ and }
                          return "$viewModel.data.\#{property_name}"
                        end
                        
                        case type.downcase
                        when 'string'
                          '"\' + value.to_s + '"'
                        when 'int', 'integer'
                          value.to_s
                        when 'double', 'float'
                          value.to_s
                        when 'bool', 'boolean'
                          return nil if value.nil?
                          value.to_s.downcase
                        when 'color'
                          format_color_value(value)
                        when 'edgeinsets'
                          format_edge_insets_value(value)
                        else
                          value.to_s
                        end
                      end
                      
                      def format_color_value(value)
                        return nil unless value
                        if value.is_a?(String) && value.start_with?('#')
                          # Parse hex color
                          hex = value.delete('#')
                          r = hex[0..1].to_i(16) / 255.0
                          g = hex[2..3].to_i(16) / 255.0
                          b = hex[4..5].to_i(16) / 255.0
                          "Color(red: \#{r}, green: \#{g}, blue: \#{b})"
                        elsif value.is_a?(Hash)
                          r = value['red'] || value['r'] || 0
                          g = value['green'] || value['g'] || 0
                          b = value['blue'] || value['b'] || 0
                          "Color(red: \#{r}, green: \#{g}, blue: \#{b})"
                        else
                          "Color.\#{value}"
                        end
                      end
                      
                      def format_edge_insets_value(value)
                        return nil unless value
                        if value.is_a?(Hash)
                          top = value['top'] || 0
                          leading = value['leading'] || value['left'] || 0
                          bottom = value['bottom'] || 0
                          trailing = value['trailing'] || value['right'] || 0
                          "EdgeInsets(top: \#{top}, leading: \#{leading}, bottom: \#{bottom}, trailing: \#{trailing})"
                        elsif value.is_a?(Numeric)
                          "EdgeInsets(top: \#{value}, leading: \#{value}, bottom: \#{value}, trailing: \#{value})"
                        else
                          nil
                        end
                      end
                    end
                  end
                end
              end
            end
          RUBY
        end

        def generate_container_check
          case @options[:is_container]
          when true
            "            # Force container mode\n            is_container = true\n"
          when false
            "            # Force non-container mode\n            is_container = false\n"
          else
            "            # Auto-detect container based on children or child\n            is_container = (@component['children'] && !@component['children'].empty?) || (@component['child'] && !@component['child'].empty?)\n"
          end
        end
        
        def generate_parameter_collection
          return "" if !@options[:attributes] || @options[:attributes].empty?
          
          lines = []
          @options[:attributes].each do |key, type|
            # Check if we need to handle the key existing vs nil differently
            if type.downcase == 'bool' || type.downcase == 'boolean'
              lines << "            if @component.key?('#{key}')"
              lines << "              value = @component['#{key}']"
              lines << "              if value.is_a?(String) && value.start_with?('@{') && value.end_with?('}')"
              lines << "                # Handle binding"
              lines << "                property_name = value[2..-2]"
              lines << '                params << "' + "#{key}: $viewModel.data." + '#{property_name}"'
              lines << "              else"
              lines << "                # Handle static value"
              lines << "                formatted_value = format_value(value, '#{type}')"
              lines << '                params << "' + "#{key}: " + '#{formatted_value}" if formatted_value != nil'
              lines << "              end"
              lines << "            end"
            else
              lines << "            if @component['#{key}']"
              lines << "              value = @component['#{key}']"
              lines << "              if value.is_a?(String) && value.start_with?('@{') && value.end_with?('}')"
              lines << "                # Handle binding"
              lines << "                property_name = value[2..-2]"
              lines << '                params << "' + "#{key}: $viewModel.data." + '#{property_name}"'
              lines << "              else"
              lines << "                # Handle static value"
              lines << "                formatted_value = format_value(value, '#{type}')"
              lines << '                params << "' + "#{key}: " + '#{formatted_value}" if formatted_value'
              lines << "              end"
              lines << "            end"
            end
          end
          lines.join("\n")
        end
        
        def generate_modifiers_code
          "            # Apply default modifiers\n            apply_modifiers"
        end

        def to_camel_case(str)
          str.split('_').map(&:capitalize).join
        end
        
        def update_membership_exceptions_if_needed
          # Try to find and update the Xcode project file
          require_relative '../../core/project_finder'
          require_relative '../../core/pbxproj_manager'
          
          if Core::ProjectFinder.setup_paths && Core::ProjectFinder.project_file_path
            begin
              manager = Core::PbxprojManager.new(Core::ProjectFinder.project_file_path)
              manager.setup_membership_exceptions
              @logger.info "Updated Xcode project to exclude extensions directory"
            rescue => e
              @logger.warn "Could not update Xcode project exclusions: #{e.message}"
            end
          end
        end
      end
    end
  end
end