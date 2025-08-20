#!/usr/bin/env ruby

require 'json'
require 'fileutils'
require_relative '../core/config_manager'
require_relative '../core/project_finder'

module SjuiTools
  module SwiftUI
    class StyleLoader
      def self.load_and_merge(component, styles_dir = nil)
        return component unless component.is_a?(Hash)
        
        # style属性がある場合、スタイルファイルを読み込んでマージ
        if component['style']
          style_name = component['style']
          style_data = load_style_file(style_name, styles_dir)
          
          if style_data
            # スタイルファイルのデータをベースに、コンポーネントのデータで上書き
            # style属性自体は削除（無限ループ防止）
            component_without_style = component.dup
            component_without_style.delete('style')
            
            # スタイルをベースに、コンポーネントのプロパティで上書き
            merged = deep_merge(style_data, component_without_style)
            component = merged
          else
            puts "Warning: Style file '#{style_name}' not found"
            # style属性を削除して続行
            component.delete('style')
          end
        end
        
        # 子要素も再帰的に処理
        if component['child']
          if component['child'].is_a?(Array)
            component['child'] = component['child'].map { |child| load_and_merge(child, styles_dir) }
          else
            component['child'] = load_and_merge(component['child'], styles_dir)
          end
        end
        
        # children属性も処理（一部のコンポーネントで使用）
        if component['children']
          if component['children'].is_a?(Array)
            component['children'] = component['children'].map { |child| load_and_merge(child, styles_dir) }
          else
            component['children'] = load_and_merge(component['children'], styles_dir)
          end
        end
        
        component
      end
      
      private
      
      def self.load_style_file(style_name, styles_dir = nil)
        # スタイルディレクトリの決定
        if styles_dir.nil?
          # Configから設定を読み込み
          config = Core::ConfigManager.load_config
          
          # プロジェクトのパスを設定
          Core::ProjectFinder.setup_paths
          source_path = Core::ProjectFinder.get_full_source_path
          
          # Config からスタイルディレクトリを取得（デフォルトは 'Styles'）
          styles_directory = config['styles_directory'] || 'Styles'
          styles_dir = File.join(source_path, styles_directory)
          
          # ディレクトリが存在しない場合
          unless Dir.exist?(styles_dir)
            # フォールバックディレクトリを試す
            fallback_dirs = [
              File.join(source_path, 'styles'),
              File.join(source_path, config['layouts_directory'] || 'Layouts', 'Styles'),
              File.join(source_path, config['layouts_directory'] || 'Layouts', 'styles')
            ]
            
            styles_dir = fallback_dirs.find { |dir| Dir.exist?(dir) }
            
            unless styles_dir
              puts "Warning: Styles directory not found. Tried: #{styles_dir}, #{fallback_dirs.join(', ')}"
              return nil
            end
          end
        end
        
        # スタイルファイルのパス
        style_file = File.join(styles_dir, "#{style_name}.json")
        
        # ファイルが存在しない場合
        unless File.exist?(style_file)
          return nil
        end
        
        # JSONファイルを読み込み
        begin
          JSON.parse(File.read(style_file))
        rescue JSON::ParserError => e
          puts "Error parsing style file '#{style_file}': #{e.message}"
          nil
        end
      end
      
      def self.deep_merge(hash1, hash2)
        return hash2 if hash1.nil?
        return hash1 if hash2.nil?
        
        result = hash1.dup
        
        hash2.each do |key, value|
          if result[key].is_a?(Hash) && value.is_a?(Hash)
            # 両方がハッシュの場合は再帰的にマージ
            result[key] = deep_merge(result[key], value)
          elsif result[key].is_a?(Array) && value.is_a?(Array)
            # 両方が配列の場合は上書き（配列のマージはしない）
            result[key] = value
          else
            # それ以外は上書き
            result[key] = value
          end
        end
        
        result
      end
    end
  end
end