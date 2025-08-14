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
                               # Create @State variable name
                               state_var = "selected#{id.split('_').map(&:capitalize).join}"
                               # Add state variable to requirements
                               add_state_variable(state_var, "Int", initial_selection.to_s)
                               "$#{state_var}"
                             end
          
          # Picker（SwiftUIのSegmented Control）
          add_line "Picker(\"\", selection: #{selection_binding}) {"
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
        
        private
        
        def add_state_variable(name, type, default_value)
          @state_variables ||= []
          @state_variables << "@State private var #{name}: #{type} = #{default_value}"
        end
      end
    end
  end
end