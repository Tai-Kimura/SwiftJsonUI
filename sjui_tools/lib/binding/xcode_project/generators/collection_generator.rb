#!/usr/bin/env ruby

require "fileutils"
require_relative '../../../core/xcode_project_manager'
require_relative '../../../core/project_finder'
require_relative '../../../core/pbxproj_manager'

module SjuiTools
  module Binding
    module XcodeProject
      module Generators
        class CollectionGenerator < ::SjuiTools::Core::PbxprojManager
          def initialize(project_file_path = nil)
            super(project_file_path)
            
            # Setup paths using ProjectFinder
            Core::ProjectFinder.setup_paths(@project_file_path)
            
            # Get configuration
            config = Core::ConfigManager.load_config
            
            # Set paths
            source_path = Core::ProjectFinder.get_full_source_path
            @view_path = File.join(source_path, config['view_directory'] || 'View')
            @core_path = File.join(source_path, 'Core')
            @layouts_path = File.join(source_path, config['layouts_directory'] || 'Layouts')
            @bindings_path = File.join(source_path, config['bindings_directory'] || 'Bindings')
            
            @xcode_manager = SjuiTools::Core::XcodeProjectManager.new(@project_file_path)
          end

          def generate(args)
            # 引数をパース: Sample/SampleList形式
            if args.nil? || args.empty?
              raise "Usage: sjui g collection <ViewFolder>/<CellName>\nExample: sjui g collection Sample/SampleList"
            end
            
            parts = args.split('/')
            if parts.length != 2
              raise "Invalid format. Use: <ViewFolder>/<CellName>"
            end
            
            view_folder_name = parts[0]
            cell_name = parts[1]
            
            # 名前の正規化
            camel_view_folder = view_folder_name.split('_').map(&:capitalize).join
            camel_cell_name = cell_name.split('_').map(&:capitalize).join
            
            puts "Generating collection cell: #{camel_cell_name} in #{camel_view_folder}"
            
            # 1. Viewフォルダ/Collectionフォルダの確認/作成
            collection_folder_path = ensure_view_folder(camel_view_folder)
            
            # 2. Collection cellファイルの作成
            cell_file_path = create_collection_cell(collection_folder_path, camel_cell_name)
            
            # 3. Xcodeプロジェクトに追加
            add_to_xcode_project(cell_file_path, camel_view_folder)
            
            # 4. JSONレイアウトファイルの作成
            json_file_path = create_cell_json_file(camel_cell_name)
            
            # 5. JSONファイルをXcodeプロジェクトに追加
            add_json_to_xcode_project(json_file_path)
            
            # 6. Bindingファイルの生成
            generate_binding_file(camel_cell_name)
            
            puts "\nSuccessfully generated collection cell: #{camel_cell_name}"
            puts "Files created:"
            puts "  - #{cell_file_path}"
            puts "  - #{json_file_path}"
            puts "\nNext steps:"
            puts "  1. Edit #{json_file_path} to design your cell layout"
            puts "  2. Run 'sjui build' to generate binding files"
            puts "  3. Implement your cell logic in the generated files"
          end

          private

          def ensure_view_folder(view_folder_name)
            # Create main view folder
            folder_path = File.join(@view_path, view_folder_name)
            
            unless Dir.exist?(folder_path)
              FileUtils.mkdir_p(folder_path)
              puts "Created view folder: #{folder_path}"
            end
            
            # Create Collection subfolder
            collection_folder_path = File.join(folder_path, "Collection")
            
            unless Dir.exist?(collection_folder_path)
              FileUtils.mkdir_p(collection_folder_path)
              puts "Created collection folder: #{collection_folder_path}"
            end
            
            collection_folder_path  # Return the Collection folder path
          end

          def create_collection_cell(collection_folder_path, cell_name)
            file_path = File.join(collection_folder_path, "#{cell_name}CollectionViewCell.swift")
            
            if File.exist?(file_path)
              puts "Warning: Collection cell file already exists: #{file_path}"
              return file_path
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
    
    var layoutPath: String {
        return "#{snake_name}_cell"
    }
    
    private lazy var _binding = #{cell_name}CellBinding(viewHolder: self)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    func setupViews() {
        // Add your cell's subview using SwiftJsonUI
        if let cellView = UIViewCreator.createView(layoutPath, target: self) {
            contentView.addSubview(cellView)
            
            // Setup constraints
            cellView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                cellView.topAnchor.constraint(equalTo: contentView.topAnchor),
                cellView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                cellView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                cellView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }
        
        _binding.bindView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset cell state here
    }
}
            SWIFT
          end

          def add_to_xcode_project(file_path, view_folder_name)
            begin
              # View/フォルダ名/Collection のグループ構造で追加
              @xcode_manager.add_file(file_path, "View/#{view_folder_name}/Collection")
              puts "Added collection cell to Xcode project"
            rescue => e
              puts "Error adding file to Xcode project: #{e.message}"
              # ファイルを削除してロールバック
              if File.exist?(file_path)
                File.delete(file_path)
                puts "Deleted: #{file_path}"
              end
              raise e
            end
          end
          
          def add_json_to_xcode_project(json_file_path)
            begin
              @xcode_manager.add_file(json_file_path, "Layouts")
              puts "Added JSON layout to Xcode project"
            rescue => e
              puts "Error adding JSON to Xcode project: #{e.message}"
              # ファイルを削除してロールバック
              if File.exist?(json_file_path)
                File.delete(json_file_path)
                puts "Deleted: #{json_file_path}"
              end
              raise e
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
              "padding" => 16,
              "background" => "#FFFFFF",
              "child" => [
                {
                  "type" => "Label",
                  "id" => "title_label",
                  "text" => "Cell Item",
                  "fontSize" => 16,
                  "fontColor" => "#000000"
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
              custom_view_types = Core::ConfigManager.get_custom_view_types
              
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
      end
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
    project_file_path = SjuiTools::Core::ProjectFinder.find_project_file(binding_builder_dir)
    generator = SjuiTools::Binding::XcodeProject::Generators::CollectionGenerator.new(project_file_path)
    generator.generate(ARGV[0])
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end