#!/usr/bin/env ruby

require 'json'
require 'fileutils'
require_relative 'converter_factory'
require_relative 'views/base_view_converter'

class JsonToSwiftUIConverter
  def initialize
    @indent_level = 0
    @generated_code = []
    @converter_factory = ConverterFactory.new
  end

  def convert_file(json_file_path, output_path = nil)
    unless File.exist?(json_file_path)
      raise "JSON file not found: #{json_file_path}"
    end

    # JSONファイルを読み込み
    json_content = File.read(json_file_path)
    json_data = JSON.parse(json_content)

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

  private

  def generate_swiftui_view(view_name, json_data)
    @generated_code = []
    @indent_level = 0
    
    # SwiftUIのインポートとビュー定義
    add_line "import SwiftUI"
    add_line ""
    
    # テンプレート変数を収集
    helper = Object.new.extend(TemplateHelper)
    template_vars = helper.collect_template_vars(json_data)
    
    # @Stateプロパティを収集
    state_properties = collect_state_properties(json_data)
    
    add_line "struct #{view_name}View: View {"
    indent do
      # テンプレート変数からプロパティを生成
      if template_vars.any?
        add_line "// Properties for data binding"
        template_properties = helper.generate_property_definition(template_vars)
        template_properties.each do |prop|
          add_line prop
        end
        add_line ""
      end
      
      # @Stateプロパティを定義
      state_properties.each do |prop|
        add_line prop
      end
      add_line "" if state_properties.any?
      
      add_line "var body: some View {"
      indent do
        # コンバーターファクトリーを使用してコンポーネントを生成
        converter = @converter_factory.create_converter(json_data, @indent_level)
        component_code = converter.convert
        component_code.split("\n").each { |line| @generated_code << line }
      end
      add_line "}"
    end
    add_line "}"
    add_line ""
    add_line "// MARK: - Preview"
    add_line "struct #{view_name}View_Previews: PreviewProvider {"
    indent do
      add_line "static var previews: some View {"
      indent do
        if template_vars.any?
          # プレビュー用のサンプルデータを生成
          add_line "#{view_name}View("
          indent do
            generate_preview_sample_data(template_vars, helper)
          end
          add_line ")"
        else
          add_line "#{view_name}View()"
        end
      end
      add_line "}"
    end
    add_line "}"
    
    @generated_code.join("\n")
  end
  
  def generate_preview_sample_data(template_vars, helper)
    template_vars.each_with_index do |(var_name, var_info), index|
      type = helper.infer_type_from_usage(var_info)
      camel_name = helper.to_camel_case(var_name)
      
      sample_value = case type
      when 'Color'
        'Color.gray'
      when 'CGFloat'
        '8'
      when 'Bool'
        'true'
      else
        '"sample"'
      end
      
      comma = index < template_vars.length - 1 ? "," : ""
      add_line "#{camel_name}: #{sample_value}#{comma}"
    end
  end

  def collect_state_properties(component, properties = [])
    return properties unless component.is_a?(Hash)
    
    # コンポーネントタイプに基づいて@Stateプロパティを収集
    case component['type']
    when 'TextField'
      id = component['id'] || 'textField'
      properties << "@State private var #{id}Text = \"\""
    when 'TextView'
      id = component['id'] || 'textEditor'
      properties << "@State private var #{id}Text = \"\""
    when 'Switch'
      id = component['id'] || 'toggle'
      properties << "@State private var #{id}IsOn = false"
    when 'Check'
      id = component['id'] || 'checkbox'
      properties << "@State private var #{id}IsChecked = false"
    end
    
    # 子要素も再帰的に処理
    if component['child'].is_a?(Array)
      component['child'].each do |child|
        collect_state_properties(child, properties)
      end
    end
    
    properties.uniq
  end

  def add_line(line)
    @generated_code << ("    " * @indent_level + line)
  end

  def add_modifier(modifier)
    @generated_code.last << modifier
  end

  def add_modifier_line(modifier)
    add_line "    #{modifier}"
  end

  def indent(&block)
    @indent_level += 1
    yield
    @indent_level -= 1
  end
end

# コマンドライン実行
if __FILE__ == $0
  if ARGV.length < 1
    puts "Usage: ruby json_to_swiftui_converter.rb <json_file_path> [output_path]"
    puts "Example: ruby json_to_swiftui_converter.rb _navigation_bar.json NavigationBarView.swift"
    exit 1
  end

  begin
    converter = JsonToSwiftUIConverter.new
    converter.convert_file(ARGV[0], ARGV[1])
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end