# frozen_string_literal: true

require "json"
require "time"
require "fileutils"
require_relative '../core/logger'
require_relative '../core/project_finder'
require_relative '../core/config_manager'

module SjuiTools
  module SwiftUI
    class BuildCacheManager
      def initialize(base_path = nil)
        # Get project root path
        Core::ProjectFinder.setup_paths
        @base_path = base_path || Core::ProjectFinder.get_full_source_path || Dir.pwd
        @cache_dir = File.join(@base_path, '.sjui_cache')
        FileUtils.mkdir_p(@cache_dir) unless Dir.exist?(@cache_dir)
        @last_updated_file = File.join(@cache_dir, "swiftui_last_updated.txt")
        @including_file = File.join(@cache_dir, "swiftui_including.json")
        @style_dependencies_file = File.join(@cache_dir, "swiftui_style_deps.json")
      end

      # Get last update timestamp
      def load_last_updated
        return nil unless File.exist?(@last_updated_file)
        
        File.open(@last_updated_file, "r") do |file|
          begin
            Time.parse(file.read)
          rescue => ex
            Core::Logger.debug "Error parsing last updated time: #{ex.message}"
            nil
          end
        end
      end

      # Get previous including file information
      def load_last_including_files
        return {} unless File.exist?(@including_file)
        
        File.open(@including_file, "r") do |file|
          JSON.parse(file.read)
        end
      rescue => ex
        Core::Logger.debug "Error loading including files: #{ex.message}"
        {}
      end

      # Get style dependencies
      def load_style_dependencies
        return {} unless File.exist?(@style_dependencies_file)
        
        File.open(@style_dependencies_file, "r") do |file|
          JSON.parse(file.read)
        end
      rescue => ex
        Core::Logger.debug "Error loading style dependencies: #{ex.message}"
        {}
      end

      # Check if file needs update
      def needs_update?(file_path, last_updated, layout_path, last_including_files, style_dependencies = {})
        return true if last_updated.nil?
        
        file_name = File.basename(file_path, ".*")
        stat = File::Stat.new(file_path)
        
        Core::Logger.debug "Checking #{file_name}: last modified #{stat.mtime}, last build #{last_updated}"
        
        # Check if file itself was updated
        return true if stat.mtime > last_updated
        
        # Check if any included files were updated
        including_files = last_including_files[file_name]
        if including_files
          including_files.each do |included_file|
            included_path = find_included_file(included_file, layout_path)
            if included_path && File.exist?(included_path)
              included_stat = File::Stat.new(included_path)
              if included_stat.mtime > last_updated
                Core::Logger.debug "  Include file #{included_file} was updated"
                return true
              end
            end
          end
        end
        
        # Check if any style files were updated
        styles_used = style_dependencies[file_name]
        if styles_used
          styles_used.each do |style_name|
            style_path = find_style_file(style_name)
            if style_path && File.exist?(style_path)
              style_stat = File::Stat.new(style_path)
              if style_stat.mtime > last_updated
                Core::Logger.debug "  Style file #{style_name} was updated"
                return true
              end
            end
          end
        end
        
        false
      end

      # Extract includes from JSON
      def extract_includes(json_data, includes = [])
        return includes unless json_data.is_a?(Hash)
        
        # Check for include attribute
        if json_data['include']
          includes << json_data['include']
        end
        
        # Process children recursively
        if json_data['child']
          if json_data['child'].is_a?(Array)
            json_data['child'].each { |child| extract_includes(child, includes) }
          else
            extract_includes(json_data['child'], includes)
          end
        end
        
        if json_data['children']
          if json_data['children'].is_a?(Array)
            json_data['children'].each { |child| extract_includes(child, includes) }
          else
            extract_includes(json_data['children'], includes)
          end
        end
        
        includes
      end

      # Extract style references from JSON
      def extract_styles(json_data, styles = [])
        return styles unless json_data.is_a?(Hash)
        
        # Check for style attribute
        if json_data['style']
          styles << json_data['style']
        end
        
        # Process children recursively
        if json_data['child']
          if json_data['child'].is_a?(Array)
            json_data['child'].each { |child| extract_styles(child, styles) }
          else
            extract_styles(json_data['child'], styles)
          end
        end
        
        if json_data['children']
          if json_data['children'].is_a?(Array)
            json_data['children'].each { |child| extract_styles(child, styles) }
          else
            extract_styles(json_data['children'], styles)
          end
        end
        
        styles.uniq
      end

      # Save cache
      def save_cache(including_files, style_dependencies = {})
        # Save including.json (pretty printed)
        File.open(@including_file, "w") do |file|
          file.write(JSON.pretty_generate(including_files))
        end
        
        # Save style dependencies
        File.open(@style_dependencies_file, "w") do |file|
          file.write(JSON.pretty_generate(style_dependencies))
        end
        
        # Save last_updated.txt
        File.open(@last_updated_file, "w") do |file|
          file.write(Time.now)
        end
      end

      # Clear cache (force full rebuild)
      def clear_cache
        FileUtils.rm_f(@last_updated_file)
        FileUtils.rm_f(@including_file)
        FileUtils.rm_f(@style_dependencies_file)
        Core::Logger.info "Cache cleared - next build will rebuild all files"
      end

      private

      def find_included_file(include_name, layout_path)
        # Try with underscore prefix (partial)
        path = File.join(layout_path, "_#{include_name}.json")
        return path if File.exist?(path)
        
        # Try without underscore
        path = File.join(layout_path, "#{include_name}.json")
        return path if File.exist?(path)
        
        # Try with subdirectory
        if include_name.include?('/')
          dir_parts = include_name.split('/')
          file_base = dir_parts.pop
          dir_path = dir_parts.join('/')
          
          # Try with underscore
          path = File.join(layout_path, dir_path, "_#{file_base}.json")
          return path if File.exist?(path)
          
          # Try without underscore
          path = File.join(layout_path, dir_path, "#{file_base}.json")
          return path if File.exist?(path)
        end
        
        nil
      end

      def find_style_file(style_name)
        config = Core::ConfigManager.load_config
        source_path = Core::ProjectFinder.get_full_source_path || Dir.pwd
        
        # Try configured styles directory
        styles_dir = File.join(source_path, config['styles_directory'] || 'Styles')
        path = File.join(styles_dir, "#{style_name}.json")
        return path if File.exist?(path)
        
        # Try other common locations
        ['styles', 'Layouts/Styles', 'Layouts/styles'].each do |dir|
          path = File.join(source_path, dir, "#{style_name}.json")
          return path if File.exist?(path)
        end
        
        nil
      end
    end
  end
end