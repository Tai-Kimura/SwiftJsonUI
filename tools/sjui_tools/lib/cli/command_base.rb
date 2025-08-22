# frozen_string_literal: true

module SjuiTools
  module CLI
    class CommandBase
      def run(args)
        raise NotImplementedError, "Subclasses must implement the run method"
      end
      
      protected
      
      def load_config
        require_relative '../core/config_manager'
        Core::ConfigManager.load_config
      end
      
      def project_dir
        require_relative '../core/project_finder'
        Core::ProjectFinder.project_dir
      end
      
      def project_exists?
        require_relative '../core/project_finder'
        Core::ProjectFinder.project_file_path != nil
      end
    end
  end
end