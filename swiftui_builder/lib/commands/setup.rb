require 'xcodeproj'
require 'fileutils'

module SwiftUIBuilder
  module Commands
    class Setup
      attr_reader :options, :config
      
      def initialize(options, config)
        @options = options
        @config = config
      end
      
      def execute
        puts "Setting up SwiftUI project..."
        
        # Xcodeプロジェクトを探す
        project_path = find_xcode_project
        unless project_path
          puts "Error: No Xcode project found in current directory or parent directories"
          return false
        end
        
        puts "Found Xcode project: #{project_path}"
        
        # ディレクトリ構造を作成
        create_directory_structure
        
        # SwiftJsonUIをSPMで追加
        add_swift_json_ui_package(project_path)
        
        # Swiftファイルのテンプレートを作成
        create_app_swift_if_needed(project_path)
        
        puts "\n✅ Setup completed!"
        puts "\nNext steps:"
        puts "1. Open your Xcode project"
        puts "2. Make sure SwiftJsonUI package is properly linked to your target"
        puts "3. Run 'sjui-swiftui g view Home' to generate your first view"
        
        true
      end
      
      private
      
      def find_xcode_project
        # 現在のディレクトリから上位に向かって.xcodeprojを探す
        current_dir = Dir.pwd
        5.times do
          projects = Dir.glob(File.join(current_dir, '*.xcodeproj'))
          return projects.first if projects.any?
          
          parent = File.dirname(current_dir)
          break if parent == current_dir
          current_dir = parent
        end
        
        nil
      end
      
      def create_directory_structure
        # プロジェクトルートを探す
        project_root = find_project_root
        
        paths = @config['paths'] || {
          'layouts' => './Layouts',
          'views' => './Views',
          'components' => './Components',
          'includes' => './includes'
        }
        
        paths.each do |key, path|
          full_path = File.join(project_root, path)
          FileUtils.mkdir_p(full_path)
          puts "Created directory: #{full_path}"
        end
        
        # .gitkeepファイルを作成
        paths.each do |key, path|
          full_path = File.join(project_root, path)
          gitkeep = File.join(full_path, '.gitkeep')
          File.write(gitkeep, '') unless File.exist?(gitkeep)
        end
      end
      
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
      
      def add_swift_json_ui_package(project_path)
        begin
          project = Xcodeproj::Project.open(project_path)
          
          # 既にSwiftJsonUIが追加されているか確認
          existing_package = project.root_object.package_references.find do |ref|
            ref.respond_to?(:repositoryURL) && 
            ref.repositoryURL&.include?('SwiftJsonUI')
          end
          
          if existing_package
            puts "SwiftJsonUI package is already added to the project"
            return
          end
          
          # SwiftJsonUIパッケージを追加
          puts "Adding SwiftJsonUI package..."
          
          # Package referenceを作成
          package_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
          package_ref.repositoryURL = 'https://github.com/Tai-Kimura/SwiftJsonUI'
          package_ref.requirement = {
            'kind' => 'upToNextMajorVersion',
            'minimumVersion' => '7.0.0'
          }
          
          # Root objectにパッケージを追加
          project.root_object.package_references << package_ref
          
          # メインターゲットを探す
          main_target = project.targets.find { |t| t.type == :application }
          
          if main_target
            # Package productを作成
            package_product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
            package_product.package = package_ref
            package_product.product_name = 'SwiftJsonUI'
            
            # ターゲットに依存関係を追加
            main_target.package_product_dependencies << package_product
            
            puts "Added SwiftJsonUI to target: #{main_target.name}"
          else
            puts "Warning: Could not find application target"
          end
          
          # プロジェクトを保存
          project.save
          puts "✅ SwiftJsonUI package added successfully"
          
        rescue => e
          puts "Error adding SwiftJsonUI package: #{e.message}"
          puts "You may need to add it manually in Xcode:"
          puts "1. File > Add Package Dependencies..."
          puts "2. Enter: https://github.com/Tai-Kimura/SwiftJsonUI"
          puts "3. Version: 7.0.0 up to next major"
        end
      end
      
      def create_app_swift_if_needed(project_path)
        project_dir = File.dirname(project_path)
        project_name = File.basename(project_path, '.xcodeproj')
        
        # App.swiftのパスを推定
        app_swift_paths = [
          File.join(project_dir, project_name, 'App.swift'),
          File.join(project_dir, project_name, "#{project_name}App.swift"),
          File.join(project_dir, 'App.swift'),
          File.join(project_dir, "#{project_name}App.swift")
        ]
        
        # 既存のApp.swiftを探す
        existing_app = app_swift_paths.find { |path| File.exist?(path) }
        
        if existing_app
          puts "Found existing App.swift: #{existing_app}"
          # HotLoaderのimportを追加する提案
          content = File.read(existing_app)
          unless content.include?('import SwiftJsonUI')
            puts "\nTo enable HotLoader, add this import to your App.swift:"
            puts "  import SwiftJsonUI"
            puts "\nAnd initialize HotLoader in your App's init:"
            puts "  #if DEBUG"
            puts "  HotLoader.instance.isHotLoadEnabled = true"
            puts "  #endif"
          end
        else
          # App.swiftが見つからない場合
          puts "\nNote: Could not find App.swift file"
          puts "Make sure to import SwiftJsonUI and enable HotLoader in your App file"
        end
      end
    end
  end
end