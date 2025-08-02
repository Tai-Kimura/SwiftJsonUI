#!/usr/bin/env ruby

require_relative 'views/label_converter'
require_relative 'views/button_converter'
require_relative 'views/view_converter'
require_relative 'views/textfield_converter'
require_relative 'views/image_converter'
require_relative 'views/scrollview_converter'
require_relative 'views/segment_converter'
require_relative 'views/progress_converter'
require_relative 'views/slider_converter'
require_relative 'views/indicator_converter'
require_relative 'views/table_converter'
require_relative 'views/collection_converter'
require_relative 'views/web_converter'
require_relative 'views/radio_converter'
require_relative 'views/selectbox_converter'
require_relative 'views/network_image_converter'
require_relative 'views/blur_converter'
require_relative 'views/gradient_view_converter'
require_relative 'views/icon_label_converter'

class ConverterFactory
  def create_converter(component, indent_level = 0)
    component_type = component['type']
    
    case component_type
    when 'Label'
      LabelConverter.new(component, indent_level)
    when 'IconLabel'
      IconLabelConverter.new(component, indent_level)
    when 'Button'
      ButtonConverter.new(component, indent_level)
    when 'View', 'SafeAreaView'
      ViewConverter.new(component, indent_level, self)
    when 'GradientView'
      GradientViewConverter.new(component, indent_level, self)
    when 'Blur'
      BlurConverter.new(component, indent_level, self)
    when 'TextField'
      TextFieldConverter.new(component, indent_level)
    when 'Image', 'CircleImage'
      ImageConverter.new(component, indent_level)
    when 'NetworkImage'
      NetworkImageConverter.new(component, indent_level)
    when 'Scroll'
      ScrollViewConverter.new(component, indent_level, self)
    when 'TextView'
      TextViewConverter.new(component, indent_level)
    when 'Switch'
      SwitchConverter.new(component, indent_level)
    when 'Check'
      CheckboxConverter.new(component, indent_level)
    when 'Radio'
      RadioConverter.new(component, indent_level)
    when 'Segment'
      SegmentConverter.new(component, indent_level)
    when 'Progress'
      ProgressConverter.new(component, indent_level)
    when 'Slider'
      SliderConverter.new(component, indent_level)
    when 'Indicator'
      IndicatorConverter.new(component, indent_level)
    when 'Table'
      TableConverter.new(component, indent_level)
    when 'Collection'
      CollectionConverter.new(component, indent_level)
    when 'SelectBox'
      SelectBoxConverter.new(component, indent_level)
    when 'Web'
      WebConverter.new(component, indent_level)
    else
      # デフォルトコンバーター
      DefaultConverter.new(component, indent_level)
    end
  end
end

# 追加のコンバータークラス
class TextViewConverter < BaseViewConverter
  def convert
    id = @component['id'] || "textEditor"
    
    add_line "@State private var #{id}Text = \"\""
    add_line "TextEditor(text: $#{id}Text)"
    
    # fontSize
    if @component['fontSize']
      add_modifier_line ".font(.system(size: #{@component['fontSize']}))"
    end
    
    # fontColor
    if @component['fontColor']
      color = hex_to_swiftui_color(@component['fontColor'])
      add_modifier_line ".foregroundColor(#{color})"
    end
    
    apply_modifiers
    generated_code
  end
end

class SwitchConverter < BaseViewConverter
  def convert
    id = @component['id'] || "toggle"
    
    add_line "@State private var #{id}IsOn = false"
    add_line "Toggle(\"\", isOn: $#{id}IsOn)"
    add_modifier_line ".labelsHidden()"
    
    apply_modifiers
    generated_code
  end
end

class CheckboxConverter < BaseViewConverter
  def convert
    id = @component['id'] || "checkbox"
    
    add_line "@State private var #{id}IsChecked = false"
    add_line "Image(systemName: #{id}IsChecked ? \"checkmark.square.fill\" : \"square\")"
    add_modifier_line ".onTapGesture {"
    indent do
      add_line "#{id}IsChecked.toggle()"
    end
    add_line "}"
    
    apply_modifiers
    generated_code
  end
end

class DefaultConverter < BaseViewConverter
  def convert
    add_line "Text(\"Unsupported component: #{@component['type']}\")"
    add_modifier_line ".foregroundColor(.red)"
    
    apply_modifiers
    generated_code
  end
end