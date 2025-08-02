#!/usr/bin/env ruby

require_relative 'base_view_converter'

class SegmentConverter < BaseViewConverter
  def convert
    id = @component['id'] || 'segment'
    items = @component['items'] || []
    
    # @Stateプロパティ
    add_line "@State private var selected#{id.split('_').map(&:capitalize).join} = 0"
    
    # Picker（SwiftUIのSegmented Control）
    add_line "Picker(\"\", selection: $selected#{id.split('_').map(&:capitalize).join}) {"
    indent do
      items.each_with_index do |item, index|
        add_line "Text(\"#{item}\").tag(#{index})"
      end
    end
    add_line "}"
    add_modifier_line ".pickerStyle(.segmented)"
    
    # 共通のモディファイアを適用
    apply_modifiers
    
    generated_code
  end
end