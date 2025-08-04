require 'json'
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
        config_file = options[:config] || 'config.json'
        
        if File.exist?(config_file) && !options[:force]
          puts "Configuration file already exists: #{config_file}"
          puts "Use --force to overwrite"
          return false
        end
        
        # Find project name
        project_name = find_project_name
        
        # Default configuration
        default_config = {
          "project_file_name" => project_name,
          "version" => "7.0.0-alpha",
          "mode" => "swiftui",
          "paths" => {
            "layouts" => "./Layouts",
            "views" => "./Views", 
            "components" => "./Components",
            "includes" => "./includes"
          }
        }
        
        # Write configuration file
        File.write(config_file, JSON.pretty_generate(default_config))
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
      
      def find_project_name
        # 現在のディレクトリから上位に向かって.xcodeprojを探す
        current_dir = Dir.pwd
        5.times do
          projects = Dir.glob(File.join(current_dir, '*.xcodeproj'))
          if projects.any?
            return File.basename(projects.first, '.xcodeproj')
          end
          
          parent = File.dirname(current_dir)
          break if parent == current_dir
          current_dir = parent
        end
        
        nil
      end
      
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
        
        Generate a new view:
        ```bash
        bin/sjui-swiftui g view Home
        ```
        
        Generate a partial:
        ```bash
        bin/sjui-swiftui g partial header
        ```
        
        Generate all views:
        ```bash
        bin/sjui-swiftui batch -i Layouts -o Views
        ```
        
        Watch for changes:
        ```bash
        bin/sjui-swiftui watch -i Layouts -o Views
        ```
        
        ## Configuration
        
        Edit `config.json` to customize the build process.
        README
        
        File.write('README.md', readme_content)
        puts "Created README.md"
      end
    end
  end
end