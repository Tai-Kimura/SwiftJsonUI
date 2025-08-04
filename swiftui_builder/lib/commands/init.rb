require 'yaml'
require 'fileutils'

module SwiftUIBuilder
  module Commands
    class Init
      attr_reader :options, :config
      
      def initialize(options, config)
        @options = options
        @config = config
      end
      
      def execute
        config_file = options[:config] || '.sjui-swiftui.yml'
        
        if File.exist?(config_file) && !options[:force]
          puts "Configuration file already exists: #{config_file}"
          puts "Use --force to overwrite"
          return false
        end
        
        # Default configuration
        default_config = {
          'version' => '7.0.0-alpha',
          'defaults' => {
            'type' => 'view',
            'include_path' => './includes'
          },
          'paths' => {
            'layouts' => './Layouts',
            'views' => './Views',
            'components' => './Components',
            'includes' => './includes'
          },
          'generation' => {
            'add_previews' => true,
            'import_swiftjsonui' => true,
            'default_view_name' => 'GeneratedView'
          },
          'validation' => {
            'strict' => false,
            'warn_unknown_attributes' => true
          }
        }
        
        # Write configuration file
        File.write(config_file, default_config.to_yaml)
        puts "Created configuration file: #{config_file}"
        
        # Create directory structure if requested
        if prompt_create_directories?
          create_directory_structure(default_config['paths'])
        end
        
        # Create sample files if requested
        if prompt_create_samples?
          create_sample_files(default_config['paths'])
        end
        
        true
      end
      
      private
      
      def prompt_create_directories?
        return false unless $stdin.tty?
        print "Create directory structure? (y/n): "
        response = $stdin.gets
        return false unless response
        response.chomp.downcase == 'y' || response.chomp.downcase == 'yes'
      end
      
      def prompt_create_samples?
        return false unless $stdin.tty?
        print "Create sample files? (y/n): "
        response = $stdin.gets
        return false unless response
        response.chomp.downcase == 'y' || response.chomp.downcase == 'yes'
      end
      
      def create_directory_structure(paths)
        paths.each do |key, path|
          FileUtils.mkdir_p(path)
          puts "Created directory: #{path}"
        end
      end
      
      def create_sample_files(paths)
        # Create sample layout JSON
        sample_layout = {
          'type' => 'View',
          'width' => 'matchParent',
          'height' => 'matchParent',
          'padding' => [20],
          'child' => {
            'type' => 'VStack',
            'spacing' => 16,
            'children' => [
              {
                'type' => 'Text',
                'text' => 'Welcome to SwiftUI Builder',
                'fontSize' => 24,
                'fontWeight' => 'bold'
              },
              {
                'type' => 'Text',
                'text' => 'This is a sample layout',
                'fontSize' => 16,
                'fontColor' => '#666666'
              },
              {
                'type' => 'Button',
                'text' => 'Get Started',
                'fontSize' => 18,
                'fontColor' => '#FFFFFF',
                'background' => '#007AFF',
                'cornerRadius' => 8,
                'padding' => [12, 24]
              }
            ]
          }
        }
        
        sample_file = File.join(paths['layouts'], 'sample.json')
        FileUtils.mkdir_p(File.dirname(sample_file))
        File.write(sample_file, JSON.pretty_generate(sample_layout))
        puts "Created sample file: #{sample_file}"
        
        # Create sample include
        sample_include = {
          'type' => 'Text',
          'text' => '@{title}',
          'fontSize' => '@{fontSize}',
          'fontColor' => '@{color}'
        }
        
        include_file = File.join(paths['includes'], 'title_text.json')
        FileUtils.mkdir_p(File.dirname(include_file))
        File.write(include_file, JSON.pretty_generate(sample_include))
        puts "Created include file: #{include_file}"
        
        # Create README
        readme_content = <<~README
        # SwiftUI Builder Project
        
        This project uses SwiftUI Builder to generate SwiftUI views from JSON layouts.
        
        ## Usage
        
        Generate a single view:
        ```bash
        sjui-swiftui generate Layouts/sample.json
        ```
        
        Generate all views:
        ```bash
        sjui-swiftui batch -i Layouts -o Views
        ```
        
        Watch for changes:
        ```bash
        sjui-swiftui watch -i Layouts -o Views
        ```
        
        ## Configuration
        
        Edit `.sjui-swiftui.yml` to customize the build process.
        README
        
        File.write('README.md', readme_content)
        puts "Created README.md"
      end
    end
  end
end