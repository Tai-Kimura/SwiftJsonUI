#!/usr/bin/env ruby

module TemplateHelper
  # テンプレート変数を検出してSwiftUIプロパティに変換
  def process_template_value(value)
    # 数値の場合はそのまま返す
    return value if value.is_a?(Numeric)
    
    # 文字列以外の場合もそのまま返す
    return value unless value.is_a?(String)
    
    # @{variable_name}形式のテンプレート変数を検出
    if value =~ /^@\{([^}]+)\}$/
      variable_name = $1
      return { template_var: variable_name }
    end
    
    # 複雑な式の場合（例：@{icon_type == 'emoji' ? 30 : 12}）
    if value.include?('@{') && value.include?('}')
      # シンプルな実装として、テンプレート変数として扱う
      return { template_expression: value }
    end
    
    value
  end
  
  # プロパティ名をSwiftUIに適したキャメルケースに変換
  def to_camel_case(snake_str)
    snake_str.split('_').inject { |m, p| m + p.capitalize }
  end
  
  # テンプレート変数からSwiftUIプロパティを生成
  def generate_property_definition(template_vars)
    props = []
    
    template_vars.each do |var_name, var_info|
      type = infer_type_from_usage(var_info)
      props << "let #{to_camel_case(var_name)}: #{type}"
    end
    
    props
  end
  
  # 使用状況から型を推論
  def infer_type_from_usage(var_info)
    # 使用されている属性から型を推論
    used_attrs = var_info[:used_as]
    
    # データバインディング用の配列型（Collection/Tableのdata属性）
    if used_attrs.include?('data') && var_info[:component_types]&.any? { |ct| ['Collection', 'Table'].include?(ct) }
      # 一般的なIdentifiableアイテムの配列として扱う
      return '[NotificationItem]' # TODO: アイテム型を動的に推論
    end
    
    # Color型の属性
    color_attrs = ['color', 'background', 'borderColor', 'fontColor', 'textColor', 
                   'tintColor', 'progressTintColor', 'trackTintColor']
    if used_attrs.any? { |attr| color_attrs.any? { |ca| attr.downcase.include?(ca.downcase) } }
      return 'Color'
    end
    
    # width/heightは特殊（文字列または数値）
    if used_attrs.any? { |attr| attr == 'width' || attr == 'height' }
      # SwiftUIではCGFloatとして扱うのが一般的
      return 'CGFloat'
    end
    
    # CGFloat型の属性（width/height以外）
    numeric_attrs = ['cornerRadius', 'borderWidth', 'fontSize', 
                     'padding', 'margin', 'radius', 'size']
    if used_attrs.any? { |attr| numeric_attrs.any? { |na| attr.downcase.include?(na.downcase) } }
      return 'CGFloat'
    end
    
    # Bool型の属性
    bool_attrs = ['visibility', 'hidden', 'enabled', 'selected']
    if used_attrs.any? { |attr| bool_attrs.include?(attr) }
      return 'Bool'
    end
    
    # String型の属性
    string_attrs = ['text', 'src', 'image', 'title', 'hint', 'placeholder']
    if used_attrs.any? { |attr| string_attrs.any? { |sa| attr.downcase.include?(sa.downcase) } }
      return 'String'
    end
    
    'String' # デフォルト
  end
  
  # コンポーネント内のすべてのテンプレート変数を収集
  def collect_template_vars(component, vars = {}, path = [], current_component_type = nil)
    return vars unless component.is_a?(Hash)
    
    # 現在のコンポーネントタイプを更新
    current_component_type = component['type'] if component['type']
    
    component.each do |key, value|
      if value.is_a?(String) && value =~ /^@\{([^}]+)\}$/
        var_name = $1
        vars[var_name] ||= { used_as: [], paths: [], component_types: [] }
        vars[var_name][:used_as] << key
        vars[var_name][:paths] << path + [key]
        vars[var_name][:component_types] << current_component_type if current_component_type
      elsif value.is_a?(Hash)
        # bindingオブジェクト内のdata属性を特別に処理
        if key == 'binding' && value['data'] && value['data'] =~ /^@\{([^}]+)\}$/
          var_name = $1
          vars[var_name] ||= { used_as: [], paths: [], component_types: [] }
          vars[var_name][:used_as] << 'data'
          vars[var_name][:paths] << path + [key, 'data']
          vars[var_name][:component_types] << current_component_type if current_component_type
        else
          collect_template_vars(value, vars, path + [key], current_component_type)
        end
      elsif value.is_a?(Array)
        value.each_with_index do |item, index|
          collect_template_vars(item, vars, path + [key, index], current_component_type) if item.is_a?(Hash)
        end
      end
    end
    
    vars
  end
end