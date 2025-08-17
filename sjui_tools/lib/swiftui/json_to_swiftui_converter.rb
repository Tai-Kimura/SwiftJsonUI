# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'set'
require_relative 'converter_factory'
require_relative 'views/base_view_converter'
require_relative 'action_manager'
require_relative 'binding/binding_handler_registry'
require_relative '../style_loader'

module SjuiTools
  module SwiftUI
    class JsonToSwiftUIConverter
      def initialize
        @indent_level = 0
        @generated_code = []
        @binding_registry = SjuiTools::SwiftUI::Binding::BindingHandlerRegistry.new
        @converter_factory = ConverterFactory.new(@binding_registry)
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
        
        # Styleファイルを適用
        json_data = SjuiTools::StyleLoader.load_and_merge(json_data)
        
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
        
        # Apply styles
        json_data = SjuiTools::StyleLoader.load_and_merge(json_data)
        
        # Process includes
        json_data = process_includes(json_data, File.dirname(json_file_path))
        
        # Convert to SwiftUI code
        @state_variables = []
        @action_manager = ActionManager.new
        @onclick_actions = Set.new
        
        # Extract onclick actions from JSON
        extract_onclick_actions(json_data)
        
        # Convert the main component
        view_code = convert_component(json_data, 0)  # Indent level 0, will be indented by view_updater
        
        [view_code, @onclick_actions.to_a]
      end
      
      def extract_onclick_actions(json_data)
        if json_data.is_a?(Hash)
          # Check for onclick attribute
          if json_data['onclick'] && json_data['onclick'].is_a?(String)
            @onclick_actions.add(json_data['onclick'])
          end
          
          # Process children
          if json_data['child']
            if json_data['child'].is_a?(Array)
              json_data['child'].each do |child|
                extract_onclick_actions(child)
              end
            else
              extract_onclick_actions(json_data['child'])
            end
          end
        elsif json_data.is_a?(Array)
          json_data.each do |item|
            extract_onclick_actions(item)
          end
        end
      end
      
      def process_includes(json_data, base_dir)
        return json_data unless json_data.is_a?(Hash)
        
        # includeがある場合、Includeタイプのコンポーネントとして扱う
        if json_data['include']
          # includeをそのままIncludeコンポーネントとして扱う
          json_data['type'] = 'Include'
          # includeファイルの存在チェック（エラー早期発見のため）
          include_file_path = File.join(base_dir, "#{json_data['include']}.json")
          unless File.exist?(include_file_path)
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
        
        # SwiftUIとSwiftJsonUIのインポート
        code = "import SwiftUI\n"
        code += "import SwiftJsonUI\n"
        code += "\n"
        
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
        // PreferenceKey for collecting view frames
        struct ViewFramePreferenceKey: PreferenceKey {
            static var defaultValue: [String: CGRect] = [:]
            static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
                value.merge(nextValue()) { _, new in new }
            }
        }
        
        SWIFT
      end
    end
  end
end