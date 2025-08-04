#!/usr/bin/env ruby

require "fileutils"
require "json"
require_relative '../../xcode_project_manager'
require_relative '../../../core/project_finder'
require_relative '../pbxproj_manager'
require_relative '../../../core/config_manager'

module SjuiTools
  module Binding
    module Generators
      class ViewGenerator < PbxprojManager
        def initialize(name, options = {})
          @name = name
          @options = options
          
          # Setup project paths
          unless Core::ProjectFinder.setup_paths
            raise "Could not find project file (.xcodeproj or Package.swift)"
          end
          
          @project_file_path = Core::ProjectFinder.find_project_file
          super(@project_file_path)
          
          base_dir = File.expand_path('../..', File.dirname(__FILE__))
          
          # ProjectFinderを使用してパスを設定
          paths = Core::ProjectFinder.setup_paths(base_dir, @project_file_path)
          @view_path = paths.view_path
          @layout_path = paths.layout_path
          @xcode_manager = XcodeProjectManager.new(@project_file_path)
        end

        def generate
          view_name = @name
          is_root = @options[:root] || false
          # 名前の正規化
          camel_name = view_name.split('_').map(&:capitalize).join
          snake_name = view_name.downcase
          
          puts "Generating view files for: #{camel_name}"
          if is_root
            puts "Setting as root view controller"
          end
          
          # 1. Viewフォルダの作成
          view_folder_path = create_view_folder(camel_name)
          
          # 2. ViewControllerファイルの作成
          view_controller_path = create_view_controller(view_folder_path, camel_name)
          
          # 3. JSONファイルの作成
          json_path = create_json_file(snake_name)
          
          # 4. Xcodeプロジェクトに追加
          add_to_xcode_project([view_controller_path, json_path])
          
          # 5. rootオプションが指定された場合、AppDelegateを修正
          if is_root
            update_app_delegate(camel_name)
          end
          
          puts "Successfully generated:"
          puts "  - View folder: #{view_folder_path}"
          puts "  - ViewController: #{view_controller_path}"
          puts "  - JSON layout: #{json_path}"
          if is_root
            puts "  - Updated AppDelegate to use #{camel_name}ViewController as root"
          end
          
          # 6. 自動的にbuildコマンドを実行してbindingファイルを生成
          puts "\nRunning build command to generate binding files..."
          run_build_command
          
          puts "\nView generation completed successfully!"
          puts "Next steps:"
          puts "  - Edit #{json_path} to customize your layout"
          if is_root
            puts "  - Your app will now launch with #{camel_name}ViewController as the initial screen"
          end
        end

        private

        def find_project_file
          # binding_builderフォルダの親ディレクトリから上に向かってpbxprojファイルを検索
          search_dir = @project_root
          
          # 最大5階層まで検索
          5.times do
            # 現在のディレクトリ内でpbxprojファイルを検索
            Dir.glob("#{search_dir}/**/*.pbxproj").each do |pbxproj_path|
              # project.pbxprojファイルを見つけた場合
              if File.basename(pbxproj_path) == "project.pbxproj"
                puts "Found Xcode project: #{pbxproj_path}"
                return pbxproj_path
              end
            end
            
            # 一つ上の階層に移動
            parent_dir = File.dirname(search_dir)
            break if parent_dir == search_dir # ルートディレクトリに到達
            search_dir = parent_dir
          end
          
          # 見つからない場合はエラーを発生
          raise "Could not find project.pbxproj file. Please ensure you're in a project directory with an Xcode project."
        end

        def create_view_folder(camel_name)
          folder_path = "#{@view_path}/#{camel_name}"
          FileUtils.mkdir_p(folder_path)
          puts "Created folder: #{folder_path}"
          folder_path
        end

        def create_view_controller(folder_path, camel_name)
          file_path = "#{folder_path}/#{camel_name}ViewController.swift"
          
          content = generate_view_controller_content(camel_name)
          
          File.write(file_path, content)
          puts "Created ViewController: #{file_path}"
          file_path
        end

        def create_json_file(snake_name)
          file_path = "#{@layout_path}/#{snake_name}.json"
          
          content = generate_json_content
          
          File.write(file_path, content)
          puts "Created JSON layout: #{file_path}"
          file_path
        end

        def generate_view_controller_content(camel_name)
          snake_name = snake_name_from_camel(camel_name)
          <<~SWIFT
      import UIKit
      import SwiftJsonUI

      class #{camel_name}ViewController: BaseViewController {
          
          override var layoutPath: String {
              get {
                  return "#{snake_name}"
              }
          }
          
          private lazy var _binding = #{camel_name}Binding(viewHolder: self)
          
          override var binding: BaseBinding {
              get {
                  return _binding
              }
          }
              
          class func newInstance() -> #{camel_name}ViewController {
              let v = #{camel_name}ViewController()
              v.title = "title_#{snake_name}".localized()
              return v
          }
          
          override func viewDidLoad() {
              super.viewDidLoad()
              self.view.addSubview(UIViewCreator.createView(layoutPath, target: self)!)
              attachViewToProperty()
          }
      }
          SWIFT
        end

        def generate_json_content
          require 'json'
          content = {
            "type" => "SafeAreaView",
            "id" => "main_view",
            "width" => "matchParent",
            "height" => "matchParent",
            "background" => "FFFFFF",
            "child" => [
              {
                "type" => "Label",
                "id" => "title_label",
                "text" => "Welcome to your new view!",
                "textAlignment" => "center"
              }
            ]
          }
          JSON.pretty_generate(content)
        end

        def add_to_xcode_project(file_paths)
          created_files = []
          
          # 作成されたファイルを記録
          file_paths.each { |file_path| created_files << file_path }
          
          safe_pbxproj_operation([], created_files) do
            # ViewControllerファイルを追加
            view_controller_path = nil
            json_path = nil
            
            file_paths.each do |file_path|
              file_name = File.basename(file_path)
              if file_name.include?("ViewController.swift")
                view_controller_path = file_path
                folder_name = File.basename(File.dirname(file_path))
                @xcode_manager.add_view_controller_file(file_name, folder_name, nil)
              elsif file_name.end_with?(".json")
                json_path = file_path
              end
            end
            
            # JSONファイルをLayoutsグループに追加
            if json_path
              require_relative '../../adders/json_adder'
              JsonAdder.add_json_file(@xcode_manager, json_path, "Layouts")
            end
            
            puts "Added files to Xcode project"
          end
        end

        def run_build_command
          begin
            # JsonLoaderとImportModuleManagerをrequire
            require_relative '../../json_loader'
            require_relative '../../import_module_manager'
            
            # configから カスタムビュータイプを読み込んで設定
            base_dir = File.expand_path('../..', File.dirname(__FILE__))
            custom_view_types = Core::ConfigManager.get_custom_view_types(base_dir)
            
            # カスタムビュータイプを設定
            view_type_mappings = {}
            import_mappings = {}
            
            custom_view_types.each do |view_type, config|
              if config['class_name']
                view_type_mappings[view_type.to_sym] = config['class_name']
              end
              if config['import_module']
                import_mappings[view_type] = config['import_module']
              end
            end
            
            # View typeの拡張
            JsonLoader.view_type_set.merge!(view_type_mappings) unless view_type_mappings.empty?
            
            # Importマッピングの追加
            import_mappings.each do |type, module_name|
              ImportModuleManager.add_type_import_mapping(type, module_name)
            end
            
            # JsonLoaderを実行
            loader = JsonLoader.new(nil, @project_file_path)
            loader.start_analyze
            
            puts "Successfully generated binding files"
          rescue => e
            puts "Warning: Could not generate binding files: #{e.message}"
            puts "You can run 'sjui build' manually to generate binding files"
          end
        end

        def snake_name_from_camel(camel_name)
          camel_name.gsub(/([A-Z])/, '_\1').downcase.sub(/^_/, '')
        end

        def update_app_delegate(camel_name)
          # SceneDelegate.swiftファイルを探す
          project_dir = File.dirname(File.dirname(@project_file_path))
          scene_delegate_path = find_scene_delegate_file(project_dir)
          
          if scene_delegate_path.nil?
            puts "Warning: Could not find SceneDelegate.swift file"
            return
          end

          puts "Updating SceneDelegate: #{scene_delegate_path}"
          
          # SceneDelegate.swiftの内容を読み込む
          content = File.read(scene_delegate_path)
          
          # 安全にSceneDelegateを更新
          updated_content = safely_update_scene_delegate(content, camel_name)
          
          # ファイルに書き戻す
          File.write(scene_delegate_path, updated_content)
          puts "SceneDelegate updated successfully"
        end

        def find_scene_delegate_file(project_dir)
          # プロジェクトディレクトリから再帰的にSceneDelegate.swiftを検索
          Dir.glob("#{project_dir}/**/SceneDelegate.swift").first
        end

        def safely_update_scene_delegate(content, camel_name)
          # scene(_:willConnectTo:options:)メソッドを更新
          content = update_scene_will_connect_safely(content, camel_name)
          content
        end

        def update_scene_will_connect_safely(content, camel_name)
          # scene(_:willConnectTo:options:)メソッドを探す（ネストした波括弧に対応）
          method_start = content.index(/func scene\([^)]+willConnectTo[^{]*\{/)
          
          if method_start
            # メソッドの開始位置から波括弧のバランスを計算してメソッド終了位置を特定
            brace_count = 0
            method_end = nil
            i = method_start
            
            while i < content.length
              if content[i] == '{'
                brace_count += 1
              elsif content[i] == '}'
                brace_count -= 1
                if brace_count == 0
                  method_end = i
                  break
                end
              end
              i += 1
            end
            
            if method_end
              # メソッドの内容を抽出
              method_content = content[method_start..method_end]
              
              # 既にrootViewController設定があるかチェック
              if method_content.include?("window?.rootViewController")
                # 既に設定済みの場合はViewControllerクラス名だけを更新
                updated_method = update_existing_root_view_controller(method_content, camel_name)
                content[method_start..method_end] = updated_method
                puts "Updated root ViewController to #{camel_name}ViewController in existing SceneDelegate setup"
              else
                # 新しいコンテンツを生成
                new_method = generate_complete_scene_method(camel_name)
                content[method_start..method_end] = new_method
                puts "Added new root ViewController setup for #{camel_name}ViewController"
              end
              
              content
            else
              puts "Warning: Could not find end of scene(_:willConnectTo:options:) method"
              content
            end
          else
            puts "Warning: Could not find scene(_:willConnectTo:options:) method"
            content
          end
        end

        def update_existing_root_view_controller(method_content, camel_name)
          # 既存のViewController名を新しい名前に置き換え
          method_content.gsub(/(\w+)ViewController\.newInstance\(\)/, "#{camel_name}ViewController.newInstance()")
        end

        def generate_complete_scene_method(camel_name)
          <<~SWIFT.chomp
      func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
              // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
              // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
              // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
              guard let windowScene = (scene as? UIWindowScene) else { return }
              
              window = UIWindow(windowScene: windowScene)
              let rootViewController = #{camel_name}ViewController.newInstance()
              let navigationController = UINavigationController(rootViewController: rootViewController)
              window?.rootViewController = navigationController
              window?.makeKeyAndVisible()
          }
          SWIFT
        end

        def generate_scene_method_content(camel_name)
          "        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.\n        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.\n        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).\n        guard let windowScene = (scene as? UIWindowScene) else { return }\n        \n        window = UIWindow(windowScene: windowScene)\n        let rootViewController = #{camel_name}ViewController.newInstance()\n        let navigationController = UINavigationController(rootViewController: rootViewController)\n        window?.rootViewController = navigationController\n        window?.makeKeyAndVisible()\n"
        end
      end
    end
  end
end

# コマンドライン実行
if __FILE__ == $0
  if ARGV.length != 1
    puts "Usage: ruby view_generator.rb <view_name>"
    puts "Example: ruby view_generator.rb sample"
    exit 1
  end

  view_name = ARGV[0]
  
  begin
    generator = SjuiTools::Binding::Generators::ViewGenerator.new(view_name)
    generator.generate
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end