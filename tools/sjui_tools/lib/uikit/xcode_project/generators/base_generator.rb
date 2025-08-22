# frozen_string_literal: true

require 'fileutils'
require_relative '../../core/project_finder'
require_relative '../../core/config_manager'
require_relative '../../core/template_engine'

module SjuiTools
  module UIKit
    module Generators
      class BaseGenerator
        attr_reader :name, :options

        def initialize(name, options = {})
          @name = name
          @options = options
          setup_paths
        end

        def generate
          raise NotImplementedError, "Subclasses must implement the generate method"
        end

        protected

        def setup_paths
          @project_dir = Core::ProjectFinder.project_dir
          @source_path = Core::ProjectFinder.get_full_source_path
          @config = Core::ConfigManager.load_config
        end

        def ensure_directory(path)
          FileUtils.mkdir_p(path) unless Dir.exist?(path)
        end

        def write_file(path, content)
          ensure_directory(File.dirname(path))
          File.write(path, content)
          puts "Created: #{relative_path(path)}"
        end

        def relative_path(path)
          Pathname.new(path).relative_path_from(Pathname.new(@project_dir)).to_s
        rescue
          path
        end

        def class_name
          Core::TemplateEngine.snake_to_camel(name)
        end

        def layouts_path
          File.join(@source_path, @config['layouts_directory'])
        end

        def bindings_path
          File.join(@source_path, @config['bindings_directory'])
        end

        def view_path
          File.join(@source_path, @config['view_directory'])
        end

        def styles_path
          File.join(@source_path, @config['styles_directory'])
        end

        def core_path
          File.join(@project_dir, 'Core')
        end

        def file_exists?(path)
          File.exist?(path)
        end

        def add_to_xcode_project(file_path, group_name)
          return unless Core::ProjectFinder.project_file_path&.end_with?('.xcodeproj')
          
          require_relative '../../core/xcode_project_manager'
          manager = XcodeProjectManager.new(Core::ProjectFinder.project_file_path)
          manager.add_file(file_path, group_name)
        rescue => e
          puts "Warning: Failed to add file to Xcode project: #{e.message}"
        end
      end
    end
  end
end