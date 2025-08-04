# frozen_string_literal: true

require 'erb'

module SjuiTools
  module Core
    class TemplateEngine
      def self.render(template_content, variables = {})
        # Create binding with variables
        b = binding
        variables.each do |key, value|
          b.local_variable_set(key, value)
        end
        
        # Render ERB template
        erb = ERB.new(template_content, trim_mode: '-')
        erb.result(b)
      end

      def self.render_file(template_path, variables = {})
        template_content = File.read(template_path)
        render(template_content, variables)
      end

      # Common template helpers
      def self.capitalize_first(string)
        return '' if string.nil? || string.empty?
        string[0].upcase + string[1..-1]
      end

      def self.snake_to_camel(string)
        string.split('_').map { |part| capitalize_first(part) }.join
      end

      def self.camel_to_snake(string)
        string.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
              .gsub(/([a-z\d])([A-Z])/, '\1_\2')
              .downcase
      end

      # Generate code block with proper indentation
      def self.indent(content, level = 1, indent_string = '    ')
        return '' if content.nil? || content.empty?
        
        indent = indent_string * level
        content.lines.map { |line| 
          line.strip.empty? ? line : "#{indent}#{line}"
        }.join
      end

      # Format array of strings for code generation
      def self.format_array(items, indent_level = 0)
        return '[]' if items.nil? || items.empty?
        
        if items.length == 1
          "[#{items.first}]"
        else
          indent = '    ' * indent_level
          inner_indent = '    ' * (indent_level + 1)
          
          "[\n" +
          items.map { |item| "#{inner_indent}#{item}" }.join(",\n") +
          "\n#{indent}]"
        end
      end

      # Format hash for code generation
      def self.format_hash(hash, indent_level = 0)
        return '{}' if hash.nil? || hash.empty?
        
        if hash.length == 1 && hash.values.first.to_s.length < 40
          "{ #{format_hash_pair(hash.first)} }"
        else
          indent = '    ' * indent_level
          inner_indent = '    ' * (indent_level + 1)
          
          "{\n" +
          hash.map { |k, v| "#{inner_indent}#{format_hash_pair([k, v])}" }.join(",\n") +
          "\n#{indent}}"
        end
      end

      private

      def self.format_hash_pair(pair)
        key, value = pair
        formatted_value = case value
        when String
          "\"#{value}\""
        when Symbol
          ":#{value}"
        when Hash
          format_hash(value)
        when Array
          format_array(value.map { |v| v.is_a?(String) ? "\"#{v}\"" : v.to_s })
        else
          value.to_s
        end
        
        "#{key}: #{formatted_value}"
      end
    end
  end
end