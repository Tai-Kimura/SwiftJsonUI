require 'thor'
require 'json'
require 'yaml'
require 'fileutils'
require 'pathname'

module SwiftUIBuilder
  class CLI < Thor
    def self.exit_on_failure?
      true
    end
    
    # Configuration file management
    class_option :config, type: :string, default: 'config.json', 
                 desc: 'Path to configuration file'
    
    
    desc "batch", "Generate SwiftUI code for multiple JSON files"
    method_option :input, aliases: '-i', type: :string, required: true,
                  desc: 'Input directory containing JSON files'
    method_option :output, aliases: '-o', type: :string, required: true,
                  desc: 'Output directory for SwiftUI files'
    method_option :pattern, aliases: '-p', type: :string, default: '**/*.json',
                  desc: 'File pattern to match'
    def batch
      Commands::Batch.new(options, config).execute
    end
    
    desc "watch", "Watch JSON files and auto-generate SwiftUI code"
    method_option :input, aliases: '-i', type: :string, required: true,
                  desc: 'Directory to watch'
    method_option :output, aliases: '-o', type: :string, required: true,
                  desc: 'Output directory'
    def watch
      Commands::Watch.new(options, config).execute
    end
    
    desc "validate FILE", "Validate a JSON file against SwiftJsonUI schema"
    method_option :strict, type: :boolean, default: false,
                  desc: 'Enable strict validation'
    def validate(file)
      Commands::Validate.new(options, config).execute(file)
    end
    
    desc "init", "Initialize configuration file"
    method_option :force, type: :boolean, default: false,
                  desc: 'Overwrite existing configuration'
    def init
      Commands::Init.new(options, config).execute
    end
    
    desc "setup", "Setup project with SwiftJsonUI SPM package"
    def setup
      Commands::Setup.new(options, config).execute
    end
    
    desc "version", "Show version information"
    def version
      puts "SwiftUI Builder for SwiftJsonUI v7.0.0-alpha"
    end
    
    private
    
    def config
      @config ||= load_config
    end
    
    def load_config
      config_file = options[:config]
      return {} unless File.exist?(config_file)
      
      begin
        JSON.parse(File.read(config_file))
      rescue => e
        say "Warning: Failed to load config file: #{e.message}", :yellow
        {}
      end
    end
  end
end

# Require command files after class definitions
require_relative 'commands/generate'
require_relative 'commands/batch'
require_relative 'commands/watch'
require_relative 'commands/validate'
require_relative 'commands/init'
require_relative 'commands/setup'