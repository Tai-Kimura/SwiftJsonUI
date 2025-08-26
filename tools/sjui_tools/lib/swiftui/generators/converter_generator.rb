# frozen_string_literal: true

require 'fileutils'
require 'json'
require_relative '../../core/logger'
require_relative 'swift_component_generator'

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
          mappings_file = File.join(Dir.pwd, 'tools', 'sjui_tools', 'lib', 'swiftui', 'views', 'extensions', 'converter_mappings.rb')
          
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
          content.sub!(/(CONVERTER_MAPPINGS = \{[^}]*)(        \}\.freeze)/m) do
            existing_mappings = $1
            closing = $2
            
            # Add comma to last mapping if there are existing mappings
            if existing_mappings =~ /[^{\s]/
              "#{existing_mappings}\n#{new_mapping}\n#{closing}"
            else
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
            
            require_relative '../../converters/base_converter'
            
            module SjuiTools
              module SwiftUI
                module Views
                  module Extensions
                    class #{@class_name} < Converters::BaseConverter
                      def convert
                        result = []
                        
            #{generate_container_check}
                        # Generate component with parameters
                        component_line = "\#{indent}#{@component_pascal_case}("
                        
                        # Collect parameters
                        params = []
            #{generate_parameter_collection}
                        
                        if is_container
                          # Container component with children
                          if params.empty?
                            result << "\#{indent}#{@component_pascal_case} {"
                          else
                            result << component_line
                            @indent_level += 1
                            params.each_with_index do |param, index|
                              if index == params.length - 1
                                result << "\#{indent}\#{param}"
                              else
                                result << "\#{indent}\#{param},"
                              end
                            end
                            @indent_level -= 1
                            result << "\#{indent}) {"
                          end
                          
                          # Process children
                          process_children(result)
                          
                          result << "\#{indent}}"
                        else
                          # Non-container component
                          if params.empty?
                            result << "\#{indent}#{@component_pascal_case}()"
                          else
                            result << component_line
                            @indent_level += 1
                            params.each_with_index do |param, index|
                              if index == params.length - 1
                                result << "\#{indent}\#{param}"
                              else
                                result << "\#{indent}\#{param},"
                              end
                            end
                            @indent_level -= 1
                            result << "\#{indent})"
                          end
                        end
                        
            #{generate_modifiers_code}
                        
                        result
                      end
                      
                      private
                      
                      def component_name
                        "#{@component_pascal_case}"
                      end
                      
                      # Process children components (handles both 'children' and 'child' keys)
                      def process_children(result)
                        @indent_level += 1
                        
                        # Handle both 'children' and 'child' keys (both are arrays)
                        child_array = @component['children'] || @component['child']
                        
                        if child_array && child_array.is_a?(Array)
                          child_array.each do |child|
                            child_converter = @factory.create_converter(child, @indent_level, @action_manager, @registry, @binding_registry)
                            result.concat(child_converter.convert)
                          end
                        end
                        
                        @indent_level -= 1
                      end
                      
                      # Helper method to format value based on type
                      def format_value(value, type)
                        case type.downcase
                        when 'string'
                          return nil unless value
                          '"\' + value.to_s + '"'
                        when 'int', 'integer'
                          return nil unless value
                          value.to_s
                        when 'double', 'float'
                          return nil unless value
                          value.to_s
                        when 'bool', 'boolean'
                          return nil unless value
                          value.to_s.downcase
                        when 'color'
                          format_color_value(value)
                        when 'edgeinsets'
                          format_edge_insets_value(value)
                        else
                          return nil unless value
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
            lines << "            if @component['#{key}']"
            lines << "              formatted_value = format_value(@component['#{key}'], '#{type}')"
            lines << "              params << \"#{key}: \\#\{formatted_value}\" if formatted_value"
            lines << "            end"
          end
          lines.join("\n")
        end
        
        def generate_modifiers_code
          if @options[:use_default_attributes]
            "            # Apply default modifiers\n            apply_common_modifiers(result)"
          else
            ""
          end
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