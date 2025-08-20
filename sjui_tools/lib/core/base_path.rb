# frozen_string_literal: true

module SjuiTools
  module Core
    class BasePath
      # Find the root directory of sjui_tools
      def self.root
        @root ||= find_root
      end

      # Find config file path
      def self.config_path(filename = 'config.json')
        File.join(root, 'config', filename)
      end

      # Find the root directory by looking for characteristic files
      def self.find_root
        current = File.expand_path(File.dirname(__FILE__))
        
        # Walk up the directory tree looking for sjui_tools directory
        while current != '/'
          if File.basename(current) == 'sjui_tools' && 
             File.exist?(File.join(current, 'lib')) &&
             File.exist?(File.join(current, 'bin'))
            return current
          end
          current = File.dirname(current)
        end
        
        # If not found, use a fallback based on the current file location
        # This file is in lib/core/, so go up two levels
        File.expand_path('../..', File.dirname(__FILE__))
      end

      # Get the project root (parent of sjui_tools)
      def self.project_root
        File.dirname(root)
      end
    end
  end
end