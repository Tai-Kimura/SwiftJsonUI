#!/usr/bin/env ruby

require "fileutils"
require_relative '../../xcode_project_manager'
require_relative '../../../core/project_finder'
require_relative '../../pbxproj_manager'

class CollectionGenerator < PbxprojManager
  def initialize(project_file_path = nil)
    super(project_file_path)
    base_dir = File.expand_path('../..', File.dirname(__FILE__))
    
    # ProjectFinderを使用してパスを設定
    paths = ProjectFinder.setup_paths(base_dir, @project_file_path)
    @view_path = paths.view_path
    @core_path = paths.core_path
    @layouts_path = paths.layout_path
    @bindings_path = paths.bindings_path
    @xcode_manager = XcodeProjectManager.new(@project_file_path)
  end

  def generate(args)
    # 引数をパース: Sample/SampleList形式
    if args.nil? || args.empty?
      raise "Usage: sjui g collection <ViewFolder>/<CellName>\nExample: sjui g collection Sample/SampleList"
    end
    
    parts = args.split('/')
    if parts.length != 2
      raise "Invalid format. Use: <ViewFolder>/<CellName>\nExample: sjui g collection Sample/SampleList"
    end
    
    view_folder = parts[0]
    cell_name = parts[1]
    
    # 名前の正規化
    camel_view_folder = view_folder.split('_').map(&:capitalize).join
    camel_cell_name = cell_name.split('_').map(&:capitalize).join
    
    puts "Generating collection cell: #{camel_cell_name} in #{camel_view_folder}"
    
    # 1. BaseCollectionViewCellの存在確認
    check_base_collection_view_cell
    
    # 2. Viewフォルダの存在確認
    view_folder_path = check_view_folder(camel_view_folder)
    
    # 3. Collectionフォルダの作成
    collection_folder_path = create_collection_folder(view_folder_path)
    
    # 4. CollectionViewCellファイルの作成
    cell_file_path = create_collection_cell(collection_folder_path, camel_cell_name)
    
    # 5. JSONレイアウトファイルの作成
    json_file_path = create_cell_json_file(camel_cell_name)
    
    # 6. Xcodeプロジェクトに追加
    add_to_xcode_project(cell_file_path, camel_view_folder)
    
    # 6.5. JSONファイルもXcodeプロジェクトに追加
    add_json_to_xcode_project(json_file_path)
    
    # 7. バインディングファイルの生成
    generate_binding_file(camel_cell_name)
    
    puts "\nSuccessfully generated:"
    puts "  - Collection cell: #{cell_file_path}"
    puts "  - JSON layout: #{json_file_path}"
    puts "  - Binding file: #{@bindings_path}/#{camel_cell_name}CellBinding.swift"
    puts "\nNext steps:"
    puts "  - Edit the JSON layout file to design your cell"
    puts "  - Register the cell in your collection view using #{camel_cell_name}CollectionViewCell.cellIdentifier"
  end

  private

  def check_base_collection_view_cell
    base_cell_path = File.join(@core_path, "Base", "BaseCollectionViewCell.swift")
    unless File.exist?(base_cell_path)
      raise "BaseCollectionViewCell.swift not found.\nPlease run 'sjui setup' first to create the Base classes."
    end
  end

  def check_view_folder(folder_name)
    folder_path = File.join(@view_path, folder_name)
    unless Dir.exist?(folder_path)
      raise "View folder '#{folder_name}' not found at: #{folder_path}\nPlease check the folder name or create the view first with 'sjui g view #{folder_name.downcase}'"
    end
    folder_path
  end

  def create_collection_folder(view_folder_path)
    collection_path = File.join(view_folder_path, "Collection")
    FileUtils.mkdir_p(collection_path)
    puts "Created/Using Collection folder: #{collection_path}"
    collection_path
  end

  def create_collection_cell(collection_folder_path, cell_name)
    file_path = File.join(collection_folder_path, "#{cell_name}CollectionViewCell.swift")
    
    if File.exist?(file_path)
      raise "Collection cell already exists: #{file_path}"
    end
    
    content = generate_collection_cell_content(cell_name)
    File.write(file_path, content)
    puts "Created collection cell: #{file_path}"
    file_path
  end

  def generate_collection_cell_content(cell_name)
    snake_name = cell_name.gsub(/([A-Z])/, '_\1').downcase.sub(/^_/, '')
    <<~SWIFT
import UIKit
import SwiftJsonUI

class #{cell_name}CollectionViewCell: BaseCollectionViewCell {
    
    static let cellIdentifier = "#{cell_name}CollectionViewCell"
    
    private lazy var _binding = #{cell_name}CellBinding(viewHolder: self)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        if let view = UIViewCreator.createView("#{snake_name}_cell", target: self) {
            self.contentView.addSubview(view)
            self._binding.bindView()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
    SWIFT
  end

  def add_to_xcode_project(file_path, view_folder_name)
    created_files = [file_path]
    
    safe_pbxproj_operation([], created_files) do
      @xcode_manager.add_collection_cell_file(file_path, view_folder_name)
      puts "Added collection cell to Xcode project"
    end
  end
  
  def add_json_to_xcode_project(json_file_path)
    created_files = [json_file_path]
    
    safe_pbxproj_operation([], created_files) do
      @xcode_manager.add_json_file(json_file_path, "Layouts")
      puts "Added JSON layout to Xcode project"
    end
  end

  def create_cell_json_file(cell_name)
    snake_name = cell_name.gsub(/([A-Z])/, '_\1').downcase.sub(/^_/, '')
    file_path = File.join(@layouts_path, "#{snake_name}_cell.json")
    
    if File.exist?(file_path)
      puts "JSON layout file already exists: #{file_path}"
      return file_path
    end
    
    content = generate_cell_json_content(cell_name)
    File.write(file_path, content)
    puts "Created JSON layout: #{file_path}"
    file_path
  end

  def generate_cell_json_content(cell_name)
    require 'json'
    content = {
      "type" => "View",
      "id" => "cell_view",
      "width" => "matchParent",
      "height" => "wrapContent",
      "padding" => "16",
      "background" => "FFFFFF",
      "child" => [
        {
          "type" => "Label",
          "id" => "title_label",
          "text" => "#{cell_name} Cell",
          "textSize" => "16",
          "textColor" => "000000"
        }
      ]
    }
    JSON.pretty_generate(content)
  end

  def generate_binding_file(cell_name)
    begin
      # JsonLoaderとImportModuleManagerをrequire
      require_relative '../../json_loader'
      require_relative '../../import_module_manager'
      require_relative '../../../core/config_manager'
      
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
      
      puts "Successfully generated binding file"
    rescue => e
      puts "Warning: Could not generate binding file: #{e.message}"
      puts "You can run 'sjui build' manually to generate binding files"
    end
  end
end

# コマンドライン実行
if __FILE__ == $0
  if ARGV.length != 1
    puts "Usage: ruby collection_generator.rb <ViewFolder>/<CellName>"
    puts "Example: ruby collection_generator.rb Sample/SampleList"
    exit 1
  end

  begin
    # binding_builderディレクトリから検索開始
    binding_builder_dir = File.expand_path("../../", __FILE__)
    project_file_path = ProjectFinder.find_project_file(binding_builder_dir)
    generator = CollectionGenerator.new(project_file_path)
    generator.generate(ARGV[0])
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end