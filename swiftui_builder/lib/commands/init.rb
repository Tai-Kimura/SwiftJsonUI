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
        # プロジェクトルートを探す
        project_root = find_project_root
        config_file = File.join(project_root, options[:config] || 'config.json')
        
        if File.exist?(config_file) && !options[:force]
          puts "Configuration file already exists: #{config_file}"
          puts "Use --force to overwrite"
          return false
        end
        
        # Find project name and source directory
        project_name = find_project_name
        source_directory = find_source_directory
        
        # Default configuration (binding_builder compatible)
        default_config = {
          "project_name" => project_name || "",
          "project_file_name" => project_name || "",
          "source_directory" => source_directory || "",
          "layouts_directory" => "Layouts",
          "views_directory" => "Views",
          "components_directory" => "Components",
          "includes_directory" => "includes",
          "mode" => "swiftui",
          "version" => "7.0.0-alpha"
        }
        
        # Write configuration file
        File.write(config_file, JSON.pretty_generate(default_config))
        puts "Created configuration file: #{config_file}"
        
        # Create directory structure if requested
        if prompt_create_directories?
          create_directory_structure(default_config)
        end
        
        # Create sample files if requested
        if prompt_create_samples?
          create_sample_files(default_config)
        end
        
        true
      end
      
      private
      
      def find_project_root
        # swiftui_builderディレクトリの親ディレクトリがプロジェクトルート
        current_dir = File.dirname(File.dirname(File.dirname(__FILE__)))
        parent = File.dirname(current_dir)
        
        # .xcodeprojが存在するディレクトリを探す
        5.times do
          if Dir.glob(File.join(parent, '*.xcodeproj')).any?
            return parent
          end
          new_parent = File.dirname(parent)
          break if new_parent == parent
          parent = new_parent
        end
        
        # 見つからない場合は、swiftui_builderの親ディレクトリを使用
        File.dirname(current_dir)
      end
      
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
      
      def find_source_directory
        # swiftui_builderの親ディレクトリから探す
        project_root = find_project_root
        
        # プロジェクトルート直下にiOSアプリファイルがあるかチェック
        # SwiftUIアプリの主要ファイルを優先
        ios_files = ['App.swift', 'ContentView.swift', 'AppDelegate.swift', 'SceneDelegate.swift', 'Info.plist']
        if ios_files.any? { |file| File.exist?(File.join(project_root, file)) }
          # ファイルがプロジェクトルートにある場合は空文字を返す
          return ""
        end
        
        # サブディレクトリを探す
        Dir.entries(project_root).each do |entry|
          next if entry.start_with?('.')
          next if entry == 'swiftui_builder'
          
          dir_path = File.join(project_root, entry)
          next unless File.directory?(dir_path)
          
          # iOSアプリファイルが含まれているディレクトリを探す
          if ios_files.any? { |file| File.exist?(File.join(dir_path, file)) }
            return entry
          end
        end
        
        # 見つからない場合は、プロジェクト名と同じディレクトリがあればそれを使用
        project_name = find_project_name
        if project_name && File.directory?(File.join(project_root, project_name))
          return project_name
        end
        
        # それでも見つからない場合は空文字を返す
        ""
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
      
      def create_directory_structure(config)
        project_root = find_project_root
        source_dir = config['source_directory'] || ''
        base_path = source_dir.empty? ? project_root : File.join(project_root, source_dir)
        
        dirs = {
          'layouts' => config['layouts_directory'] || 'Layouts',
          'views' => config['views_directory'] || 'Views',
          'components' => config['components_directory'] || 'Components',
          'includes' => config['includes_directory'] || 'includes'
        }
        
        dirs.each do |key, dir|
          full_path = File.join(base_path, dir)
          FileUtils.mkdir_p(full_path)
          puts "Created directory: #{full_path}"
        end
      end
      
      def create_sample_files(config)
        project_root = find_project_root
        source_dir = config['source_directory'] || ''
        base_path = source_dir.empty? ? project_root : File.join(project_root, source_dir)
        
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
        
        layouts_dir = config['layouts_directory'] || 'Layouts'
        sample_file = File.join(base_path, layouts_dir, 'sample.json')
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
        
        includes_dir = config['includes_directory'] || 'includes'
        include_file = File.join(base_path, includes_dir, 'title_text.json')
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
        
        File.write(File.join(project_root, 'README.md'), readme_content)
        puts "Created README.md"
      end
    end
  end
end