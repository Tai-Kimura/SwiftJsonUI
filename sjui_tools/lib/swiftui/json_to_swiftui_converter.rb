# frozen_string_literal: true

require 'json'
require 'fileutils'
require_relative 'converter_factory'
require_relative 'views/base_view_converter'
require_relative 'action_manager'

module SjuiTools
  module SwiftUI
    class JsonToSwiftUIConverter
      def initialize
        @indent_level = 0
        @generated_code = []
        @converter_factory = ConverterFactory.new
        @action_manager = ActionManager.new
        @state_variables = []
      end

      def convert_file(json_file_path, output_path = nil)
        unless File.exist?(json_file_path)
          raise "JSON file not found: #{json_file_path}"
        end

        # JSONファイルを読み込み
        json_content = File.read(json_file_path)
        json_data = JSON.parse(json_content)
        
        # includeを処理
        json_data = process_includes(json_data, File.dirname(json_file_path))

        # ファイル名からビュー名を生成
        base_name = File.basename(json_file_path, '.json')
        # _プレフィックスを削除
        base_name = base_name.sub(/^_/, '')
        # スネークケースをパスカルケースに変換
        view_name = base_name.split('_').map(&:capitalize).join

        # SwiftUIコードを生成
        swift_code = generate_swiftui_view(view_name, json_data)

        # 出力パスが指定されていない場合は、入力ファイルと同じディレクトリに出力
        if output_path.nil?
          output_path = File.join(File.dirname(json_file_path), "#{view_name}View.swift")
        end

        # ファイルに書き込み
        File.write(output_path, swift_code)
        puts "Generated SwiftUI view: #{output_path}"
        
        output_path
      end
      
      def convert_component(json_data, indent_level = 0)
        @indent_level = indent_level
        converter = @converter_factory.create_converter(json_data, @indent_level, @action_manager)
        result = converter.convert
        
        # Collect state variables from converter
        if converter.respond_to?(:state_variables) && converter.state_variables
          @state_variables.concat(converter.state_variables)
        end
        
        result
      end
      
      # Simple method to convert JSON file to SwiftUI view code only
      def convert_json_to_view(json_file_path)
        unless File.exist?(json_file_path)
          raise "JSON file not found: #{json_file_path}"
        end
        
        # Read and parse JSON
        json_content = File.read(json_file_path)
        json_data = JSON.parse(json_content)
        
        # Process includes
        json_data = process_includes(json_data, File.dirname(json_file_path))
        
        # Convert to SwiftUI code
        @state_variables = []
        @action_manager = ActionManager.new
        
        # Convert the main component
        view_code = convert_component(json_data, 2)  # Indent level 2 for inside generatedBody
        
        view_code
      end
      
      def process_includes(json_data, base_dir)
        return json_data unless json_data.is_a?(Hash)
        
        # includeがある場合の処理
        if json_data['include']
          include_path = json_data['include']
          variables = json_data['variables'] || {}
          
          # includeファイルのパスを構築
          include_file_path = if include_path.include?('/')
            # サブディレクトリがある場合: "common/header" → "common/_header.json"
            components = include_path.split('/')
            directory = components[0...-1].join('/')
            filename = "_#{components.last}"
            File.join(base_dir, directory, "#{filename}.json")
          else
            # サブディレクトリがない場合: "header" → "_header.json"
            File.join(base_dir, "_#{include_path}.json")
          end
          
          # ファイルが存在しない場合は、プレフィックスなしも試す
          unless File.exist?(include_file_path)
            include_file_path = File.join(base_dir, "#{include_path}.json")
          end
          
          if File.exist?(include_file_path)
            # includeファイルを読み込み
            include_content = File.read(include_file_path)
            
            # 変数を置換
            variables.each do |key, value|
              if key.start_with?('@@')
                # @@から始まる変数はそのまま置換
                include_content = include_content.gsub(key, value.to_s)
              else
                # それ以外は"key"形式で置換
                include_content = include_content.gsub("\"#{key}\"", "\"#{value}\"")
              end
            end
            
            # パースして返す
            included_data = JSON.parse(include_content)
            
            # includeしたデータを再帰的に処理
            return process_includes(included_data, File.dirname(include_file_path))
          else
            raise "Include file not found: #{include_file_path}"
          end
        end
        
        # childの処理
        if json_data['child']
          if json_data['child'].is_a?(Array)
            json_data['child'] = json_data['child'].map { |child| process_includes(child, base_dir) }
          else
            json_data['child'] = process_includes(json_data['child'], base_dir)
          end
        end
        
        json_data
      end

      private

      def generate_swiftui_view(view_name, json_data)
        # Reset state for new view
        @state_variables = []
        
        # SwiftUIのインポート
        code = "import SwiftUI\n\n"
        
        # 相対配置が必要な場合はPreferenceKeyを定義
        if needs_preference_key?(json_data)
          code += generate_preference_key_definition
        end
        
        # ビュー構造体の定義
        code += "struct #{view_name}View: View {\n"
        
        # JSONコンポーネントをSwiftUIに変換（状態変数を収集）
        converter = @converter_factory.create_converter(json_data, 2, @action_manager)
        body_code = converter.convert
        
        # Collect state variables from converter
        if converter.respond_to?(:state_variables) && converter.state_variables
          @state_variables.concat(converter.state_variables)
        end
        
        # Add state variables
        if @state_variables.any?
          @state_variables.uniq.each do |state_var|
            code += "    #{state_var}\n"
          end
          code += "    \n"
        end
        
        # Add body
        code += "    var body: some View {\n"
        code += body_code
        code += "    }\n"
        
        # Add action handlers
        action_handlers = @action_manager.generate_action_handlers
        if action_handlers.any?
          code += "    \n"
          code += "    // MARK: - Action Handlers\n"
          action_handlers.each do |handler_lines|
            handler_lines.each do |line|
              code += "    #{line}\n"
            end
          end
        end
        
        # ビュー構造体の終了
        code += "}\n\n"
        
        # プレビューの追加
        code += "struct #{view_name}View_Previews: PreviewProvider {\n"
        code += "    static var previews: some View {\n"
        code += "        #{view_name}View()\n"
        code += "    }\n"
        code += "}\n"
        
        code
      end
      
      def needs_preference_key?(json_data)
        return false unless json_data.is_a?(Hash)
        
        # childが配列の場合
        if json_data['child'].is_a?(Array)
          json_data['child'].any? do |child|
            child['alignTopOfView'] || child['alignBottomOfView'] || 
            child['alignLeftOfView'] || child['alignRightOfView'] ||
            needs_preference_key?(child)
          end
        elsif json_data['child']
          child = json_data['child']
          child['alignTopOfView'] || child['alignBottomOfView'] || 
          child['alignLeftOfView'] || child['alignRightOfView'] ||
          needs_preference_key?(child)
        else
          false
        end
      end
      
      def generate_preference_key_definition
        <<~SWIFT
        // PreferenceKey for relative positioning
        struct ViewOffsetKey: PreferenceKey {
            static var defaultValue: CGPoint = .zero
            static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
                value = nextValue()
            }
        }
        
        // Helper for relative positioning
        extension View {
            func savePosition(id: String) -> some View {
                self.background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ViewOffsetKey.self,
                            value: geometry.frame(in: .named("ZStackCoordinateSpace")).origin
                        )
                    }
                )
            }
        }
        
        SWIFT
      end
    end
  end
end