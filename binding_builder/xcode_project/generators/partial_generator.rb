#!/usr/bin/env ruby

require "fileutils"
require "json"
require_relative "../pbxproj_manager"
require_relative "../../project_finder"

class PartialGenerator < PbxprojManager
  def initialize(project_file_path = nil)
    super(project_file_path)
    base_dir = File.expand_path('../..', File.dirname(__FILE__))
    
    # ProjectFinderを使用してパスを設定
    paths = ProjectFinder.setup_paths(base_dir, @project_file_path)
    @layouts_path = paths.layout_path
  end

  def generate(partial_name)
    # 引数チェック
    if partial_name.nil? || partial_name.empty?
      raise "Usage: sjui g partial <partial_name>\nExample: sjui g partial navigation_bar"
    end
    
    # パスとファイル名を分離
    parts = partial_name.split('/')
    if parts.length > 1
      # サブディレクトリがある場合
      subdir = parts[0..-2].join('/')
      base_name = parts[-1]
    else
      # サブディレクトリがない場合
      subdir = nil
      base_name = partial_name
    end
    
    # 名前の正規化（キャメルケースをスネークケースに変換）
    snake_name = base_name.gsub(/([A-Z])/, '_\1').downcase.sub(/^_/, '')
    
    puts "Generating partial: #{snake_name}" + (subdir ? " in #{subdir}/" : "")
    
    # 1. partialのJSONファイル作成（_プレフィックス付き）
    partial_file_path = create_partial_json_file(snake_name, subdir)
    
    # 2. バインディングファイルの生成
    generate_binding_file
    
    puts "\nSuccessfully generated:"
    puts "  - Partial JSON: #{partial_file_path}"
    puts "\nNext steps:"
    puts "  - Edit the JSON file to design your partial layout"
    puts "  - Include it in other layouts using the partial name: '#{snake_name}'"
  end

  private

  def create_partial_json_file(snake_name, subdir = nil)
    # ファイル名の最初に_を追加
    file_name = "_#{snake_name}.json"
    
    # サブディレクトリがある場合はパスに含める
    if subdir
      dir_path = File.join(@layouts_path, subdir)
      file_path = File.join(dir_path, file_name)
    else
      dir_path = @layouts_path
      file_path = File.join(@layouts_path, file_name)
    end
    
    if File.exist?(file_path)
      puts "Partial JSON file already exists: #{file_path}"
      return file_path
    end
    
    # ディレクトリが存在しない場合は作成（サブディレクトリも含めて）
    FileUtils.mkdir_p(dir_path) unless File.directory?(dir_path)
    
    content = generate_partial_json_content(snake_name)
    File.write(file_path, content)
    puts "Created partial JSON: #{file_path}"
    file_path
  end

  def generate_partial_json_content(snake_name)
    # Partialの基本テンプレート
    content = {
      "type" => "View",
      "id" => "#{snake_name}_container",
      "width" => "matchParent",
      "height" => "wrapContent",
      "background" => "FFFFFF",
      "padding" => "16",
      "child" => [
        {
          "type" => "Label",
          "id" => "#{snake_name}_label",
          "text" => "#{snake_name.split('_').map(&:capitalize).join(' ')} Partial",
          "textSize" => "16",
          "textColor" => "333333"
        }
      ]
    }
    JSON.pretty_generate(content)
  end

  def generate_binding_file
    begin
      # JsonLoaderとImportModuleManagerをrequire
      require_relative "../../json_loader"
      require_relative "../../import_module_manager"
      require_relative "../../config_manager"
      
      # configから カスタムビュータイプを読み込んで設定
      base_dir = File.expand_path('../..', File.dirname(__FILE__))
      custom_view_types = ConfigManager.get_custom_view_types(base_dir)
      
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
end

# コマンドライン実行
if __FILE__ == $0
  if ARGV.length != 1
    puts "Usage: ruby partial_generator.rb <partial_name>"
    puts "Example: ruby partial_generator.rb navigation_bar"
    exit 1
  end

  begin
    # binding_builderディレクトリから検索開始
    binding_builder_dir = File.expand_path("../../", __FILE__)
    project_file_path = ProjectFinder.find_project_file(binding_builder_dir)
    generator = PartialGenerator.new(project_file_path)
    generator.generate(ARGV[0])
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end