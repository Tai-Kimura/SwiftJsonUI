#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class SegmentConverter < BaseViewConverter
        def convert
          id = @component['id'] || 'segment'
          items = @component['items'] || []
          
          # selectedTabIndex プロパティの処理
          initial_selection = @component['selectedTabIndex'] || @component['selectedIndex'] || 0
          
          # Get selection binding
          selection_binding = if (@component['selectedIndex'] && is_binding?(@component['selectedIndex']))
                               "$viewModel.data.#{extract_binding_property(@component['selectedIndex'])}"
                             elsif (@component['selectedTabIndex'] && is_binding?(@component['selectedTabIndex']))
                               "$viewModel.data.#{extract_binding_property(@component['selectedTabIndex'])}"
                             else
                               # Use viewModel.data with state variable name
                               state_var = "selected#{id.split('_').map(&:capitalize).join}"
                               # Note: This needs to be defined in JSON data section
                               "$viewModel.data.#{state_var}"
                             end
          
          # Picker（SwiftUIのSegmented Control）
          add_line "Picker(\"\", selection: #{selection_binding}) {"
          indent do
            items.each_with_index do |item, index|
              # Escape double quotes in item text for Swift string literal
              escaped_item = item.gsub('"', '\\"')
              add_line "Text(\"#{escaped_item}\").tag(#{index})"
            end
          end
          add_line "}"
          add_modifier_line ".pickerStyle(.segmented)"
          
          # 共通のモディファイアを適用
          apply_modifiers
          
          generated_code
        end
      end
    end
  end
end