# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'pathname'
require_relative '../config_manager'
require_relative '../project_finder'
require_relative '../logger'

module SjuiTools
  module Core
    module Resources
      class StringManager
        def initialize
          @config = Core::ConfigManager.load_config
          @source_path = Core::ProjectFinder.get_full_source_path || Dir.pwd
          @layouts_dir = File.join(@source_path, @config['layouts_directory'] || 'Layouts')
          @resources_dir = File.join(@layouts_dir, 'Resources')
          @tmp_dir = File.join(@source_path, '.sjui_tmp')
          @extracted_strings_file = File.join(@tmp_dir, 'extracted_strings.json')
          @strings_cache = {}
        end
        
        # Process all JSON files and extract strings
        def process_json_files(json_files)
          ensure_tmp_directory
          
          # Load existing extracted strings from tmp
          extracted_data = load_extracted_strings
          
          json_files.each do |json_file|
            begin
              file_name = File.basename(json_file, '.json')
              json_content = File.read(json_file)
              json_data = JSON.parse(json_content)
              
              # Extract strings from this file
              file_strings = extract_strings_from_json(json_data, file_name)
              
              # Merge with existing data
              extracted_data['strings'][file_name] = file_strings['strings']
              extracted_data['not_defined'] = (extracted_data['not_defined'] + file_strings['not_defined']).uniq
              
              # Save to tmp file after each file processing
              save_extracted_strings(extracted_data)
            rescue JSON::ParserError => e
              Core::Logger.warn "Failed to parse #{json_file}: #{e.message}"
            rescue => e
              Core::Logger.warn "Error processing #{json_file}: #{e.message}"
            end
          end
          
          extracted_data
        end
        
        # Cache .strings files
        def cache_strings_files(string_files)
          @strings_cache = {}
          
          string_files.each do |file_path|
            full_path = File.join(@source_path, file_path)
            if File.exist?(full_path)
              Core::Logger.info "Caching strings file: #{file_path}"
              cache_strings_file(full_path)
            else
              Core::Logger.warn "Strings file not found: #{full_path}"
            end
          end
          
          Core::Logger.info "Cached #{@strings_cache.keys.length} string keys"
        end
        
        # Write strings.json with NOT_IMPLEMENTED_YET values
        def write_strings_json
          extracted_data = load_extracted_strings
          strings_file_path = File.join(@resources_dir, 'strings.json')
          
          # Prepare output data
          output_data = {}
          
          # Process extracted strings
          extracted_data['strings'].each do |file_name, strings|
            output_data[file_name] ||= {}
            strings.each do |key|
              # Check if key exists in .strings file
              full_key = "#{file_name}_#{key}"
              if @strings_cache && @strings_cache[full_key]
                output_data[file_name][key] = @strings_cache[full_key]
              else
                output_data[file_name][key] = "" # Will add comment in JSON
              end
            end
          end
          
          # Add not_defined array
          if extracted_data['not_defined'] && extracted_data['not_defined'].any?
            output_data['not_defined'] = extracted_data['not_defined']
          end
          
          # Write JSON with comments for empty values
          write_json_with_comments(strings_file_path, output_data)
          Core::Logger.success "Written strings.json to Resources"
          
          # Clean up tmp file
          cleanup_tmp_files
        end
        
        # Get summary of extracted strings
        def get_extraction_summary
          extracted_data = load_extracted_strings
          {
            'files_count' => extracted_data['strings'].keys.length,
            'not_defined_count' => extracted_data['not_defined'].length
          }
        end
        
        # Apply extracted strings to .strings files
        def apply_to_strings_files
          strings_json_path = File.join(@resources_dir, 'strings.json')
          
          unless File.exist?(strings_json_path)
            Core::Logger.warn "strings.json not found at #{strings_json_path}"
            return
          end
          
          # Load strings.json
          strings_data = JSON.parse(File.read(strings_json_path))
          
          # Get configured .strings files
          string_files = @config['string_files'] || []
          
          if string_files.empty?
            Core::Logger.info "No .strings files configured"
            return
          end
          
          # Process each .strings file
          string_files.each do |file_path|
            full_path = File.join(@source_path, file_path)
            if File.exist?(full_path)
              Core::Logger.info "Updating strings file: #{file_path}"
              update_strings_file(full_path, strings_data)
            else
              Core::Logger.warn "Strings file not found: #{full_path}"
            end
          end
          
          Core::Logger.success "Applied strings to .strings files"
        end
        
        # Main processing method called from ResourcesManager
        def process_strings(processed_files, processed_count, skipped_count, config)
          Core::Logger.info "Processing strings extraction..."
          
          # Cache .strings files if configured
          string_files = config['string_files'] || []
          if string_files.any?
            cache_strings_files(string_files)
          end
          
          # Process all changed files
          if processed_files.any?
            process_json_files(processed_files)
          end
          
          # Write strings.json with extracted strings
          if processed_count > 0 || skipped_count == 0
            write_strings_json
          end
          
          # Get summary for logging
          summary = get_extraction_summary
          Core::Logger.info "Processed #{processed_count} files, skipped #{skipped_count} unchanged files"
          Core::Logger.info "Extracted strings from #{summary['files_count']} files"
          Core::Logger.info "Found #{summary['not_defined_count']} undefined strings" if summary['not_defined_count'] > 0
        end
        
        private
        
        def ensure_tmp_directory
          FileUtils.mkdir_p(@tmp_dir) unless Dir.exist?(@tmp_dir)
        end
        
        def load_extracted_strings
          if File.exist?(@extracted_strings_file)
            begin
              JSON.parse(File.read(@extracted_strings_file))
            rescue JSON::ParserError
              { 'strings' => {}, 'not_defined' => [] }
            end
          else
            { 'strings' => {}, 'not_defined' => [] }
          end
        end
        
        def save_extracted_strings(data)
          File.write(@extracted_strings_file, JSON.pretty_generate(data))
        end
        
        def cleanup_tmp_files
          FileUtils.rm_f(@extracted_strings_file) if File.exist?(@extracted_strings_file)
        end
        
        def extract_strings_from_json(json_data, file_name)
          strings = []
          not_defined = []
          
          extract_strings_recursive(json_data, strings, not_defined, file_name)
          
          {
            'strings' => strings.uniq,
            'not_defined' => not_defined.uniq
          }
        end
        
        def extract_strings_recursive(data, strings, not_defined, file_name = nil)
          return unless data.is_a?(Hash)
          
          # Check for 'text' key
          if data['text'].is_a?(String) && !data['text'].empty?
            process_string_value(data['text'], strings, not_defined, file_name)
          end
          
          # Check for partial_attributes array
          if data['partial_attributes'].is_a?(Array)
            data['partial_attributes'].each do |attr|
              if attr.is_a?(Hash) && attr['range'].is_a?(Hash) && attr['range']['text'].is_a?(String)
                process_string_value(attr['range']['text'], strings, not_defined, file_name)
              end
            end
          end
          
          # Recursively process children and other nested structures
          data.each_value do |value|
            if value.is_a?(Hash)
              extract_strings_recursive(value, strings, not_defined, file_name)
            elsif value.is_a?(Array)
              value.each { |item| extract_strings_recursive(item, strings, not_defined, file_name) if item.is_a?(Hash) }
            end
          end
        end
        
        def process_string_value(text, strings, not_defined, file_name = nil)
          # Skip binding values (wrapped in @{})
          return if text.match?(/^@\{.*\}$/)
          
          # Check if it's snake_case
          if text.match?(/^[a-z]+(_[a-z]+)*$/)
            # Remove file name prefix if it exists
            if file_name && text.start_with?("#{file_name}_")
              key = text.sub(/^#{file_name}_/, '')
            else
              key = text
            end
            strings << key
          else
            # Direct string value - add to not_defined
            not_defined << text
          end
        end
        
        def cache_strings_file(file_path)
          @strings_cache ||= {}
          
          File.open(file_path, 'r:UTF-8') do |file|
            file.each_line do |line|
              # Parse .strings format: "key" = "value";
              if match = line.match(/^\s*"([^"]+)"\s*=\s*"([^"]*)"\s*;/)
                key = match[1]
                value = match[2]
                @strings_cache[key] = value
              end
            end
          end
        rescue => e
          Core::Logger.warn "Failed to parse strings file #{file_path}: #{e.message}"
        end
        
        def write_json_with_comments(file_path, data)
          # Ensure Resources directory exists
          FileUtils.mkdir_p(@resources_dir) unless Dir.exist?(@resources_dir)
          
          File.open(file_path, 'w:UTF-8') do |file|
            file.write("{\n")
            
            keys = data.keys
            keys.each_with_index do |key, index|
              if key == 'not_defined'
                # Write not_defined array
                file.write("  \"not_defined\": [\n")
                data[key].each_with_index do |str, i|
                  file.write("    \"#{escape_json_string(str)}\"")
                  file.write(",") if i < data[key].length - 1
                  file.write("\n")
                end
                file.write("  ]")
              else
                # Write file sections
                file.write("  \"#{key}\": {\n")
                section_keys = data[key].keys
                section_keys.each_with_index do |sub_key, i|
                  value = data[key][sub_key]
                  if value.empty?
                    file.write("    \"#{sub_key}\": \"NOT_IMPLEMENTED_YET\"")
                  else
                    file.write("    \"#{sub_key}\": \"#{escape_json_string(value)}\"")
                  end
                  file.write(",") if i < section_keys.length - 1
                  file.write("\n")
                end
                file.write("  }")
              end
              
              file.write(",") if index < keys.length - 1
              file.write("\n")
            end
            
            file.write("}\n")
          end
        end
        
        def escape_json_string(str)
          str.gsub('"', '\\"').gsub("\n", '\\n').gsub("\r", '\\r').gsub("\t", '\\t')
        end
        
        def update_strings_file(file_path, strings_data)
          # Read existing .strings file
          existing_strings = {}
          if File.exist?(file_path)
            File.open(file_path, 'r:UTF-8') do |file|
              file.each_line do |line|
                # Parse .strings format: "key" = "value";
                if match = line.match(/^\s*"([^"]+)"\s*=\s*"([^"]*)"\s*;/)
                  key = match[1]
                  value = match[2]
                  existing_strings[key] = value
                end
              end
            end
          end
          
          # Collect strings to add grouped by file
          strings_by_file = {}
          
          strings_data.each do |file_name, keys|
            # Skip 'not_defined' array
            next if file_name == 'not_defined'
            
            file_strings = []
            keys.each do |key, value|
              # Only process if value is NOT_IMPLEMENTED_YET
              if value == "NOT_IMPLEMENTED_YET"
                # Create full key with file name prefix
                full_key = "#{file_name}_#{key}"
                
                # Only add if not already in .strings file
                unless existing_strings.key?(full_key)
                  file_strings << { key: full_key, value: "NOT_IMPLEMENTED_YET" }
                end
              end
            end
            
            strings_by_file[file_name] = file_strings if file_strings.any?
          end
          
          # If there are strings to add, append them to the file
          if strings_by_file.any?
            total_count = strings_by_file.values.flatten.length
            Core::Logger.info "Adding #{total_count} new strings to #{File.basename(file_path)}"
            
            File.open(file_path, 'a:UTF-8') do |file|
              # Add a newline if file doesn't end with one
              file.write("\n") unless File.size(file_path) == 0 || File.read(file_path)[-1] == "\n"
              
              # Add main comment header
              file.write("\n/* Auto-generated strings - #{Time.now.strftime('%Y-%m-%d %H:%M:%S')} */\n")
              
              # Add strings grouped by file
              strings_by_file.each_with_index do |(file_name, file_strings), index|
                # Add blank line between files (except for the first one)
                file.write("\n") if index > 0
                
                # Add file name comment
                file.write("/* #{file_name}.json */\n")
                
                # Add each string for this file
                file_strings.each do |string_data|
                  file.write("\"#{string_data[:key]}\" = \"#{string_data[:value]}\";\n")
                end
              end
            end
          else
            Core::Logger.info "No new strings to add to #{File.basename(file_path)}"
          end
        end
      end
    end
  end
end