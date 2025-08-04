require 'json'
require 'pathname'
require 'thor'
require 'fileutils'

module SwiftUIBuilder
  module Commands
    class Generate < Thor
      def self.exit_on_failure?
        true
      end
      
      def initialize(*args)
        super
        # プロジェクトルートのconfig.jsonを読み込む
        project_root = find_project_root_for_config
        config_file = File.join(project_root, 'config.json')
        @config = if File.exist?(config_file)
                    JSON.parse(File.read(config_file))
                  else
                    {}
                  end
      end
      
      def find_project_root_for_config
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
      
      desc "view VIEW_NAME", "Generate view and JSON layout file"
      method_option :root, type: :boolean, default: false,
                    desc: 'Set as root view'
      def view(view_name)
        puts "Generating SwiftUI view: #{view_name}"
        
        # 名前の正規化
        camel_name = view_name.split('_').map(&:capitalize).join
        snake_name = view_name.gsub(/([A-Z])/, '_\1').downcase.sub(/^_/, '')
        
        # プロジェクトルートを探す
        project_root = find_project_root
        
        # ディレクトリの作成
        layouts_dir = @config.dig('paths', 'layouts') || './Layouts'
        views_dir = @config.dig('paths', 'views') || './Views'
        
        # 絶対パスに変換
        layouts_dir = File.join(project_root, layouts_dir)
        views_dir = File.join(project_root, views_dir)
        
        FileUtils.mkdir_p(layouts_dir)
        FileUtils.mkdir_p(views_dir)
        
        # JSONファイルの作成
        json_path = File.join(layouts_dir, "#{snake_name}.json")
        create_json_layout(json_path, camel_name)
        
        # SwiftUIビューの生成
        swift_path = File.join(views_dir, "#{camel_name}View.swift")
        generate_swiftui_view(json_path, swift_path, camel_name)
        
        puts "Generated:"
        puts "  Layout: #{json_path}"
        puts "  View: #{swift_path}"
        
        if options[:root]
          puts "TODO: Set as root view in App.swift"
        end
      end
      
      desc "partial PARTIAL_NAME", "Generate partial JSON layout"
      def partial(partial_name)
        puts "Generating partial: #{partial_name}"
        
        # パスの解析
        parts = partial_name.split('/')
        if parts.length > 1
          subfolder = parts[0..-2].join('/')
          name = parts[-1]
        else
          subfolder = nil
          name = partial_name
        end
        
        # プロジェクトルートを探す
        project_root = find_project_root
        
        # ディレクトリの作成
        includes_dir = @config.dig('paths', 'includes') || './includes'
        includes_dir = File.join(project_root, includes_dir)
        target_dir = subfolder ? File.join(includes_dir, subfolder) : includes_dir
        FileUtils.mkdir_p(target_dir)
        
        # パーシャルJSONの作成
        json_path = File.join(target_dir, "_#{name}.json")
        create_partial_json(json_path, name)
        
        puts "Generated partial: #{json_path}"
      end
      
      desc "collection FOLDER/NAME", "Generate collection view cell"
      def collection(path)
        parts = path.split('/')
        if parts.length != 2
          puts "Error: Please specify as ViewFolder/CellName"
          puts "Example: sjui-swiftui g collection Home/ProductCell"
          exit 1
        end
        
        folder_name = parts[0]
        cell_name = parts[1]
        
        puts "Generating collection cell: #{folder_name}/#{cell_name}"
        
        # プロジェクトルートを探す
        project_root = find_project_root
        
        # ディレクトリの作成
        views_dir = @config.dig('paths', 'views') || './Views'
        layouts_dir = @config.dig('paths', 'layouts') || './Layouts'
        
        # 絶対パスに変換
        views_dir = File.join(project_root, views_dir)
        layouts_dir = File.join(project_root, layouts_dir)
        
        view_folder = File.join(views_dir, folder_name)
        layout_folder = File.join(layouts_dir, 'cells')
        
        FileUtils.mkdir_p(view_folder)
        FileUtils.mkdir_p(layout_folder)
        
        # セルレイアウトJSONの作成
        json_path = File.join(layout_folder, "_#{cell_name.gsub(/([A-Z])/, '_\1').downcase.sub(/^_/, '')}.json")
        create_cell_json(json_path, cell_name)
        
        # TODO: コレクションビューのSwiftコード生成
        
        puts "Generated:"
        puts "  Cell layout: #{json_path}"
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
      
      def create_json_layout(path, view_name)
        layout = {
          "type" => "View",
          "width" => "matchParent",
          "height" => "matchParent",
          "padding" => [20],
          "child" => [
            {
              "type" => "Label",
              "text" => "#{view_name} View",
              "fontSize" => 24,
              "font" => "bold",
              "fontColor" => "#000000",
              "alignment" => "center"
            },
            {
              "type" => "Label",
              "text" => "Edit #{File.basename(path)} to customize this view",
              "fontSize" => 16,
              "fontColor" => "#666666",
              "alignment" => "center",
              "margin" => [20, 0, 0, 0]
            }
          ]
        }
        
        File.write(path, JSON.pretty_generate(layout))
      end
      
      def create_partial_json(path, name)
        partial = {
          "type" => "View",
          "padding" => [10],
          "background" => "#F5F5F5",
          "cornerRadius" => 8,
          "child" => {
            "type" => "Label",
            "text" => "@{text}",
            "fontSize" => "@{fontSize}",
            "fontColor" => "@{color}",
            "alignment" => "center"
          }
        }
        
        File.write(path, JSON.pretty_generate(partial))
      end
      
      def create_cell_json(path, cell_name)
        cell_layout = {
          "type" => "View",
          "width" => "matchParent",
          "height" => "wrapContent",
          "padding" => [16],
          "background" => "#FFFFFF",
          "child" => [
            {
              "type" => "Label",
              "text" => "@{title}",
              "fontSize" => 18,
              "font" => "semibold",
              "fontColor" => "#000000"
            },
            {
              "type" => "Label",
              "text" => "@{subtitle}",
              "fontSize" => 14,
              "fontColor" => "#666666",
              "margin" => [4, 0, 0, 0]
            }
          ]
        }
        
        File.write(path, JSON.pretty_generate(cell_layout))
      end
      
      def generate_swiftui_view(json_path, swift_path, view_name)
        # コンバーターのパスを取得
        converter_path = File.expand_path('../../../json_to_swiftui_converter.rb', __FILE__)
        require converter_path
        
        # JSONファイルを読み込み
        json_content = File.read(json_path)
        json_data = JSON.parse(json_content)
        
        # コンバーターでSwiftUIコードを生成
        converter = JsonToSwiftUIConverter.new
        
        # includeを処理
        if json_data['include']
          json_data = converter.process_includes(json_data, File.dirname(json_path))
        end
        
        # SwiftUIコードを生成
        swift_code = <<~SWIFT
        import SwiftUI
        import SwiftJsonUI
        
        struct #{view_name}View: View {
            var body: some View {
        #{converter.convert_component(json_data, 2)}
            }
        }
        
        struct #{view_name}View_Previews: PreviewProvider {
            static var previews: some View {
                #{view_name}View()
            }
        }
        SWIFT
        
        File.write(swift_path, swift_code)
      end
    end
  end
end