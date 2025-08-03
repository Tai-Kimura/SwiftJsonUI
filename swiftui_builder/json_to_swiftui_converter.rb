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
    
    # 子要素も再帰的に処理
    if json_data['child']
      if json_data['child'].is_a?(Array)
        json_data['child'] = json_data['child'].map { |child| process_includes(child, base_dir) }
      else
        json_data['child'] = process_includes(json_data['child'], base_dir)
      end
    elsif json_data['children']
      if json_data['children'].is_a?(Array)
        json_data['children'] = json_data['children'].map { |child| process_includes(child, base_dir) }
      else
        json_data['children'] = process_includes(json_data['children'], base_dir)
      end
    end
    
    json_data
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
      when /^\[.*\]$/ # 配列型の場合
        '[]' # 空配列をプレビューデータとして使用
      else
        '"sample"'
      end
      
      comma = index < template_vars.length - 1 ? "," : ""
      add_line "#{camel_name}: #{sample_value}#{comma}"
    end
  end

  def collect_state_properties(component, properties = [])
    return properties unless component.is_a?(Hash)
    
    # コンバーターを作成して@Stateプロパティを収集
    converter = @converter_factory.create_converter(component, 0)
    if converter.respond_to?(:state_properties)
      properties.concat(converter.state_properties)
    end
    
    # 従来の方法も残す（後方互換性のため）
    case component['type']
    when 'TextField'
      id = component['id'] || 'textField'
      properties << "@State private var #{id}Text = \"\"" unless converter.respond_to?(:state_properties)
    when 'TextView'
      id = component['id'] || 'textEditor'
      properties << "@State private var #{id}Text = \"\"" unless converter.respond_to?(:state_properties)
    when 'Switch'
      id = component['id'] || 'toggle'
      properties << "@State private var #{id}IsOn = false" unless converter.respond_to?(:state_properties)
    when 'Check'
      id = component['id'] || 'checkbox'
      properties << "@State private var #{id}IsChecked = false" unless converter.respond_to?(:state_properties)
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