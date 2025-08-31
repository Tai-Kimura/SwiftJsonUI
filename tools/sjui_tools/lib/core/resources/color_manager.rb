# frozen_string_literal: true

require 'json'
require 'fileutils'
require_relative '../logger'

module SjuiTools
  module Core
    module Resources
      class ColorManager
        def initialize(config, source_path, resources_dir)
          @config = config
          @source_path = source_path
          @resources_dir = resources_dir
          @colors_file = File.join(@resources_dir, 'colors.json')
          @defined_colors_file = File.join(@resources_dir, 'defined_colors.json')
          @extracted_colors = {}
          @undefined_colors = {}
          @colors_data = load_colors_json
          @defined_colors_data = load_defined_colors_json
        end
        
        # Main process method called from ResourcesManager
        def process_colors(processed_files, processed_count, skipped_count, config)
          return if processed_files.empty?
          
          Core::Logger.info "Extracting colors from #{processed_count} files (#{skipped_count} skipped)..."
          
          # Extract colors from JSON files
          extract_colors(processed_files)
          
          # Save updated colors.json if there are new colors
          save_colors_json if @extracted_colors.any?
          
          # Save undefined colors to defined_colors.json
          save_defined_colors_json if @undefined_colors.any?
          
          # Generate ColorManager.swift if needed
          generate_color_manager_swift if @config['resource_manager_directory']
        end
        
        # Apply extracted colors to color asset files
        def apply_to_color_assets
          # Save any pending colors to colors.json
          save_colors_json if @extracted_colors.any?
          # Save undefined colors to defined_colors.json
          save_defined_colors_json if @undefined_colors.any?
        end
        
        private
        
        # Load existing colors.json file
        def load_colors_json
          return {} unless File.exist?(@colors_file)
          
          begin
            JSON.parse(File.read(@colors_file))
          rescue JSON::ParserError => e
            Core::Logger.warn "Failed to parse colors.json: #{e.message}"
            {}
          end
        end
        
        # Load existing defined_colors.json file
        def load_defined_colors_json
          return {} unless File.exist?(@defined_colors_file)
          
          begin
            JSON.parse(File.read(@defined_colors_file))
          rescue JSON::ParserError => e
            Core::Logger.warn "Failed to parse defined_colors.json: #{e.message}"
            {}
          end
        end
        
        # Save colors data to colors.json
        def save_colors_json
          # Merge extracted colors with existing colors
          @colors_data.merge!(@extracted_colors)
          
          # Ensure Resources directory exists
          FileUtils.mkdir_p(@resources_dir)
          
          # Write colors.json
          File.write(@colors_file, JSON.pretty_generate(@colors_data))
          Core::Logger.info "Updated colors.json with #{@extracted_colors.size} new colors"
          
          # Clear extracted colors after saving
          @extracted_colors.clear
        end
        
        # Save undefined colors to defined_colors.json
        def save_defined_colors_json
          # Merge new undefined colors with existing defined colors
          @defined_colors_data.merge!(@undefined_colors)
          
          # Ensure Resources directory exists
          FileUtils.mkdir_p(@resources_dir)
          
          # Write defined_colors.json
          File.write(@defined_colors_file, JSON.pretty_generate(@defined_colors_data))
          Core::Logger.info "Updated defined_colors.json with #{@undefined_colors.size} undefined color keys"
          
          # Clear undefined colors after saving
          @undefined_colors.clear
        end
        
        # Extract color values from processed JSON files
        def extract_colors(processed_files)
          @modified_files = []
          
          Core::Logger.debug "Processing #{processed_files.size} files for colors"
          
          processed_files.each do |json_file|
            begin
              Core::Logger.debug "Processing file: #{json_file}"
              content = File.read(json_file)
              data = JSON.parse(content)
              
              # Extract and replace colors recursively from JSON structure
              modified = replace_colors_recursive(data)
              
              Core::Logger.debug "File modified: #{modified}, extracted colors: #{@extracted_colors.size}"
              
              # Save modified JSON file if any colors were replaced
              if modified
                File.write(json_file, JSON.pretty_generate(data))
                @modified_files << json_file
                Core::Logger.debug "Updated colors in: #{json_file}"
              end
            rescue JSON::ParserError => e
              Core::Logger.warn "Failed to parse #{json_file}: #{e.message}"
            rescue => e
              Core::Logger.error "Error processing #{json_file}: #{e.message}"
            end
          end
          
          if @modified_files.any?
            Core::Logger.info "Replaced colors in #{@modified_files.size} files"
          end
        end
        
        # Replace colors recursively in JSON data
        def replace_colors_recursive(data, parent_key = nil)
          modified = false
          
          case data
          when Hash
            data.each do |key, value|
              # Check if this key is a color property and value is a string
              if is_color_property?(key) && value.is_a?(String)
                # Process and replace the color value (hex or string key)
                new_value = process_and_replace_color(value)
                if new_value != value
                  data[key] = new_value
                  modified = true
                  Core::Logger.debug "Replaced #{value} with #{new_value} in #{key}"
                end
              elsif value.is_a?(Hash) || value.is_a?(Array)
                # Recurse into nested structures
                child_modified = replace_colors_recursive(value, key)
                modified ||= child_modified
              end
            end
          when Array
            data.each_with_index do |item, index|
              if item.is_a?(Hash) || item.is_a?(Array)
                child_modified = replace_colors_recursive(item, parent_key)
                modified ||= child_modified
              end
            end
          end
          
          modified
        end
        
        # Check if a property name is likely to contain a color
        def is_color_property?(key)
          # From commonAttributes, only color-related properties
          color_properties = [
            'background',
            'tapBackground',
            'borderColor'
          ]
          
          # Additional color properties not in commonAttributes but used in components
          additional_color_properties = [
            'fontColor',
            'textColor', 
            'hintColor',
            'shadowColor',
            'tintColor',
            'selectedColor',
            'unselectedColor',
            'backgroundColor',
            'strokeColor',
            'overlayColor',
            'caretColor',
            'disabledBackground'
          ]
          
          all_color_properties = color_properties + additional_color_properties
          all_color_properties.include?(key.to_s)
        end
        
        # Process and replace a color value, returning the color key
        def process_and_replace_color(color_value)
          # Handle hex colors
          if is_hex_color?(color_value)
            # Normalize hex color (uppercase, with #)
            hex_color = normalize_hex_color(color_value)
            
            # Check if color already exists in colors.json
            existing_key = find_color_key(hex_color)
            
            if existing_key
              # Color already exists, return the key
              Core::Logger.debug "Found existing color: #{existing_key} = #{hex_color}"
              return existing_key
            else
              # Generate a new key for this color
              new_key = generate_color_key(hex_color)
              
              # Add to extracted colors
              @extracted_colors[new_key] = hex_color
              Core::Logger.debug "New color found: #{new_key} = #{hex_color}"
              return new_key
            end
          # Handle string color keys
          elsif color_value.is_a?(String) && !color_value.empty?
            # Check if this color key exists in colors.json
            if @colors_data.key?(color_value) || @extracted_colors.key?(color_value)
              # Color key exists, keep it as is
              Core::Logger.debug "Color key exists: #{color_value}"
              return color_value
            elsif @defined_colors_data.key?(color_value)
              # Already in defined_colors, keep it as is
              Core::Logger.debug "Color key already in defined_colors: #{color_value}"
              return color_value
            else
              # Undefined color key, add to undefined colors list
              @undefined_colors[color_value] = nil
              Core::Logger.debug "Undefined color key found: #{color_value}"
              return color_value
            end
          else
            # Return as is for other types
            return color_value
          end
        end
        
        # Find existing key for a hex color
        def find_color_key(hex_color)
          # Check both existing colors and newly extracted colors
          all_colors = @colors_data.merge(@extracted_colors)
          all_colors.find { |key, value| value.upcase == hex_color.upcase }&.first
        end
        
        # Generate a descriptive key name based on RGB values
        def generate_color_key(hex_color)
          # Parse RGB values from hex
          rgb = parse_hex_to_rgb(hex_color)
          return 'unknown_color' unless rgb
          
          r, g, b = rgb
          
          # Calculate brightness and dominant color
          brightness = (r + g + b) / 3.0
          
          # Determine base name from brightness
          base_name = if brightness > 230
                        'white'
                      elsif brightness > 200
                        'pale'
                      elsif brightness > 150
                        'light'
                      elsif brightness > 100
                        'medium'
                      elsif brightness > 50
                        'dark'
                      elsif brightness > 20
                        'deep'
                      else
                        'black'
                      end
          
          # Find dominant color if not grayscale
          max_diff = [r, g, b].max - [r, g, b].min
          if max_diff > 30  # Not grayscale
            # Determine dominant color
            if r > g && r > b
              if r - g > 50 && r - b > 50
                color_suffix = '_red'
              elsif r > b
                color_suffix = '_orange' if g > b
                color_suffix = '_pink' if b > g * 0.7
              else
                color_suffix = '_magenta'
              end
            elsif g > r && g > b
              if g - r > 50 && g - b > 50
                color_suffix = '_green'
              elsif g > b && r > b * 0.7
                color_suffix = '_yellow'
              else
                color_suffix = '_lime'
              end
            elsif b > r && b > g
              if b - r > 50 && b - g > 50
                color_suffix = '_blue'
              elsif b > r && g > r * 0.7
                color_suffix = '_cyan'
              else
                color_suffix = '_purple'
              end
            else
              color_suffix = ''
            end
            
            base_name = base_name + color_suffix unless base_name == 'white' || base_name == 'black'
          elsif base_name != 'white' && base_name != 'black'
            base_name = base_name + '_gray'
          end
          
          # Handle duplicates by adding suffix
          final_key = base_name
          counter = 2
          all_colors = @colors_data.merge(@extracted_colors)
          
          while all_colors.key?(final_key)
            final_key = "#{base_name}_#{counter}"
            counter += 1
          end
          
          final_key
        end
        
        # Parse hex color to RGB values
        def parse_hex_to_rgb(hex_color)
          # Remove # if present
          hex = hex_color.gsub('#', '')
          
          # Support 3, 6, and 8 digit hex
          case hex.length
          when 3
            # RGB (12-bit) - expand to 6 digits
            hex = hex.chars.map { |c| c * 2 }.join
            [
              hex[0..1].to_i(16),
              hex[2..3].to_i(16),
              hex[4..5].to_i(16)
            ]
          when 6
            # RRGGBB (24-bit)
            [
              hex[0..1].to_i(16),
              hex[2..3].to_i(16),
              hex[4..5].to_i(16)
            ]
          when 8
            # RRGGBBAA (32-bit) - ignore alpha for color naming
            [
              hex[0..1].to_i(16),
              hex[2..3].to_i(16),
              hex[4..5].to_i(16)
            ]
          else
            nil
          end
        rescue
          nil
        end
        
        # Check if a value is a hex color
        def is_hex_color?(value)
          return false unless value.is_a?(String)
          # Support 3, 6, or 8 digit hex colors (RGB, RRGGBB, RRGGBBAA)
          value.match?(/^#?([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$/)
        end
        
        # Normalize hex color format
        def normalize_hex_color(hex_color)
          hex = hex_color.gsub('#', '').upcase
          
          # Convert 3-digit to 6-digit
          if hex.length == 3
            hex = hex.chars.map { |c| c * 2 }.join
          end
          
          # Keep 6 or 8 digit hex as is
          "##{hex}"
        end
        
        # Generate Swift code for ColorManager
        def generate_color_manager_swift
          return unless @config['resource_manager_directory']
          
          resource_manager_dir = File.join(@source_path, @config['resource_manager_directory'])
          FileUtils.mkdir_p(resource_manager_dir)
          
          output_file = File.join(resource_manager_dir, 'ColorManager.swift')
          
          # Combine all colors (from colors.json and defined_colors.json)
          all_colors = @colors_data.dup
          
          # Add defined colors (keys without values yet)
          @defined_colors_data.each do |key, _|
            all_colors[key] ||= nil
          end
          
          swift_code = generate_swift_code(all_colors)
          
          File.write(output_file, swift_code)
          Core::Logger.info "✓ Generated ColorManager.swift"
        end
        
        def generate_swift_code(colors)
          timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
          
          code = []
          code << "// ColorManager.swift"
          code << "// Auto-generated file - DO NOT EDIT"
          code << "// Generated at: #{timestamp}"
          code << ""
          code << "import UIKit"
          code << "import SwiftUI"
          code << "import SwiftJsonUI"
          code << ""
          code << "public struct ColorManager {"
          code << "    private init() {}"
          code << ""
          code << "    // Load colors from colors.json"
          if @colors_data.empty?
            code << "    private static let colorsData: [String: String] = [:]"
          else
            code << "    private static let colorsData: [String: String] = ["
            
            # Add defined colors from colors.json
            @colors_data.each_with_index do |(key, hex_value), index|
              comma = index < @colors_data.size - 1 ? "," : ""
              code << "        \"#{key}\": \"#{hex_value}\"#{comma}"
            end
            
            code << "    ]"
          end
          code << ""
          code << "    // UIKit colors"
          code << "    public struct uikit {"
          code << "        private init() {}"
          code << ""
          code << "        // Get UIColor by key"
          code << "        public static func color(for key: String) -> UIColor {"
          code << "            guard let hexString = ColorManager.colorsData[key] else {"
          code << "                print(\"Warning: Color key '\\(key)' not found in colors.json\")"
          code << "                return UIColor.gray // Default fallback color"
          code << "            }"
          code << "            return UIColor.colorWithHexString(hexString)"
          code << "        }"
          code << ""
          
          # Generate static UIColor accessors
          colors.keys.sort.each do |key|
            property_name = snake_to_camel(key)
            
            code << "        public static var #{property_name}: UIColor {"
            
            if @colors_data[key]
              code << "            return UIColor.colorWithHexString(\"#{@colors_data[key]}\")"
            else
              code << "            // Undefined color - needs to be defined in colors.json"
              code << "            print(\"Warning: Color '#{key}' is not defined in colors.json\")"
              code << "            return UIColor.gray // Fallback color"
            end
            
            code << "        }"
            code << ""
          end
          
          code << "    }"
          code << ""
          code << "    // SwiftUI colors"
          code << "    public struct swiftui {"
          code << "        private init() {}"
          code << ""
          code << "        // Get SwiftUI Color by key"
          code << "        public static func color(for key: String) -> Color {"
          code << "            return Color(uiColor: uikit.color(for: key))"
          code << "        }"
          code << ""
          
          # Generate static SwiftUI Color accessors
          colors.keys.sort.each do |key|
            property_name = snake_to_camel(key)
            
            code << "        public static var #{property_name}: Color {"
            code << "            return Color(uiColor: uikit.#{property_name})"
            code << "        }"
            code << ""
          end
          
          code << "    }"
          code << ""
          code << "}"
          code << ""
          code << "// Note: Color(hex:) extension is provided by SwiftJsonUI library"
          
          code.join("\n")
        end
        
        def snake_to_camel(snake_case)
          # Convert snake_case to camelCase
          # Examples: 
          #   primary_blue -> primaryBlue
          #   white_2 -> white2
          #   dark_gray -> darkGray
          parts = snake_case.split('_')
          first_part = parts.shift
          camel = first_part + parts.map(&:capitalize).join
          camel
        end
      end
    end
  end
end