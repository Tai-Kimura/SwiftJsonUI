# frozen_string_literal: true

require 'json'
require 'fileutils'
require_relative 'config_manager'
require_relative 'project_finder'
require_relative 'logger'
require_relative 'resources/string_manager'

module SjuiTools
  module Core
    class ResourcesManager
      def initialize
        @config = ConfigManager.load_config
        @source_path = ProjectFinder.get_full_source_path || Dir.pwd
        @layouts_dir = File.join(@source_path, @config['layouts_directory'] || 'Layouts')
        @resources_dir = File.join(@layouts_dir, 'Resources')
        @string_manager = Resources::StringManager.new
      end
      
      # Main method called from build command
      def process_resources(layouts_dir, last_updated = {})
        # Extract resources from JSON files
        process_resource_extraction(layouts_dir, last_updated)
        
        # Apply extracted strings to .strings files
        apply_extracted_strings
      end
      
      # Extract resources from JSON files
      def process_resource_extraction(layouts_dir, last_updated = {})
        Core::Logger.info "Processing resource extraction..."
        
        # Get all JSON files (excluding Resources folder)
        json_files = Dir.glob(File.join(layouts_dir, '**/*.json')).reject do |file|
          file.include?(File.join(layouts_dir, 'Resources'))
        end
        
        # Filter changed files
        processed_files = []
        processed_count = 0
        skipped_count = 0
        
        json_files.each do |json_file|
          begin
            relative_path = Pathname.new(json_file).relative_path_from(Pathname.new(layouts_dir)).to_s
            
            # Check if file has been modified since last build
            file_mtime = File.mtime(json_file).to_i
            if last_updated[relative_path] && last_updated[relative_path] >= file_mtime
              Core::Logger.debug "Skipping unchanged file: #{relative_path}"
              skipped_count += 1
              next
            end
            
            Core::Logger.debug "Processing: #{relative_path}"
            processed_files << json_file
            processed_count += 1
          rescue => e
            Core::Logger.warn "Error checking #{json_file}: #{e.message}"
          end
        end
        
        # Process strings through StringManager
        @string_manager.process_strings(processed_files, processed_count, skipped_count, @config)
        
        # TODO: Process colors
        # TODO: Process dimensions
        # TODO: Process other resources
      end
      
      private
      
      def apply_extracted_strings
        Core::Logger.info "Applying extracted strings to .strings files..."
        @string_manager.apply_to_strings_files
      end
    end
  end
end