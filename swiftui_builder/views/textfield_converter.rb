#!/usr/bin/env ruby

require_relative 'base_view_converter'

class TextFieldConverter < BaseViewConverter
  def convert
    # hint (SwiftJsonUIではplaceholderではなくhint)
    placeholder = @component['hint'] || ""
    id = @component['id'] || "textField"
    
    # @Stateプロパティは最初に記述
    add_line "@State private var #{id}Text = \"\""
    add_line "TextField(\"#{placeholder}\", text: $#{id}Text)"
    
    # fontSize
    if @component['fontSize']
      add_modifier_line ".font(.system(size: #{@component['fontSize']}))"
    end
    
    # fontColor
    if @component['fontColor']
      color = hex_to_swiftui_color(@component['fontColor'])
      add_modifier_line ".foregroundColor(#{color})"
    end
    
    # font
    if @component['font'] == 'bold'
      add_modifier_line ".fontWeight(.bold)"
    elsif @component['font']
      add_modifier_line ".font(.custom(\"#{@component['font']}\", size: #{@component['fontSize'] || 17}))"
    end
    
    # textFieldStyle
    if @component['borderStyle']
      style = text_field_style(@component['borderStyle'])
      add_modifier_line ".textFieldStyle(#{style})"
    end
    
    # input type (keyboard type)
    if @component['input']
      keyboard_type = input_to_keyboard_type(@component['input'])
      add_modifier_line ".keyboardType(#{keyboard_type})"
    end
    
    # contentType (for auto-fill)
    if @component['contentType']
      content_type = map_content_type(@component['contentType'])
      add_modifier_line ".textContentType(#{content_type})"
    end
    
    # onTextChange
    if @component['onTextChange']
      add_modifier_line ".onChange(of: #{id}Text) { newValue in"
      indent do
        add_line "// TODO: Implement #{@component['onTextChange']} action"
      end
      add_line "}"
    end
    
    # 共通のモディファイアを適用
    apply_modifiers
    
    generated_code
  end
  
  private
  
  def text_field_style(style)
    case style
    when 'RoundedRect', 'roundedRect'
      '.roundedBorder'
    when 'none'
      '.plain'
    else
      '.automatic'
    end
  end
  
  def input_to_keyboard_type(input)
    case input
    when 'email'
      '.emailAddress'
    when 'password'
      '.default'  # SwiftUIではセキュア入力は別途設定
    when 'number'
      '.numberPad'
    when 'decimal'
      '.decimalPad'
    when 'URL'
      '.URL'
    when 'twitter'
      '.twitter'
    when 'webSearch'
      '.webSearch'
    when 'namePhonePad'
      '.namePhonePad'
    else
      '.default'
    end
  end
  
  def map_content_type(type)
    case type
    when 'username'
      '.username'
    when 'password'
      '.password'
    when 'email'
      '.emailAddress'
    when 'name'
      '.name'
    when 'tel'
      '.telephoneNumber'
    when 'streetAddress'
      '.streetAddressLine1'
    when 'postalCode'
      '.postalCode'
    else
      '.none'
    end
  end
end