# frozen_string_literal: true

require 'fileutils'
require 'json'
require_relative '../../core/logger'

module SjuiTools
  module SwiftUI
    module Generators
      class ConverterGenerator
        def initialize(name, options = {})
          @name = name
          @class_name = to_camel_case(name) + "Converter"
          @options = options
          @logger = Core::Logger
        end

        def generate
          @logger.info "Generating custom converter: #{@class_name}"
          
          # Create converter file
          create_converter_file
          
          @logger.success "Successfully generated converter: #{@class_name}"
          @logger.info "Converter file created at: views/extensions/#{@name}_converter.rb"
          @logger.info ""
          @logger.info "To use this converter, register it in converter_factory.rb:"
          @logger.info "  when '#{to_camel_case(@name)}'"
          @logger.info "    require_relative '../views/extensions/#{@name}_converter'"
          @logger.info "    Views::Extensions::#{@class_name}.new(component, indent_level, action_manager, self, registry, @binding_registry)"
        end

        private

        def create_converter_file
          # Ensure views/extensions directory exists
          extensions_dir = File.join(Dir.pwd, 'tools', 'sjui_tools', 'lib', 'swiftui', 'views', 'extensions')
          FileUtils.mkdir_p(extensions_dir)
          
          file_path = File.join(extensions_dir, "#{@name}_converter.rb")
          
          if File.exist?(file_path)
            @logger.warn "Converter file already exists: #{file_path}"
            print "Overwrite? (y/n): "
            response = gets.chomp.downcase
            return unless response == 'y'
          end
          
          File.write(file_path, converter_template)
          @logger.info "Created converter file: #{file_path}"
        end

        def converter_template
          attributes_code = generate_attributes_code
          
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
                      
                      # Component name
                      result << "\#{indent}#{to_camel_case(@name)} {"
                      
                      @indent_level += 1
                      
                      #{attributes_code}
                      
                      # Convert children if present
                      if @component['children']
                        @component['children'].each do |child|
                          child_converter = @factory.create_converter(child, @indent_level, @action_manager, @registry, @binding_registry)
                          result.concat(child_converter.convert)
                        end
                      end
                      
                      @indent_level -= 1
                      result << "\#{indent}}"
                      
                      result
                    end
                    
                    private
                    
                    def component_name
                      "#{to_camel_case(@name)}"
                    end
                    end
                  end
                end
              end
            end
          RUBY
        end

        def generate_attributes_code
          lines = []
          
          if @options[:use_default_attributes]
            lines << "# Default attributes"
            lines << "apply_default_attributes(result)"
            lines << ""
          end
          
          if @options[:attributes] && !@options[:attributes].empty?
            lines << "# Custom attributes"
            @options[:attributes].each do |key, type|
              lines << "if @component['#{key}']"
              lines << "  result << \"\#{indent}.#{key}(@component['#{key}'])\""
              lines << "end"
              lines << ""
            end
          end
          
          lines.join("\n                  ")
        end

        def to_camel_case(str)
          str.split('_').map(&:capitalize).join
        end
      end
    end
  end
end