#!/usr/bin/env ruby

require_relative 'base_view_converter'

class RadioConverter < BaseViewConverter
  def convert
    id = @component['id'] || 'radio'
    group = @component['group'] || 'defaultGroup'
    
    # @Stateプロパティ（グループごとに管理）
    add_line "@State private var selected#{group.split('_').map(&:capitalize).join}: String = \"\""
    
    # カスタムRadioButton実装
    add_line "HStack {"
    indent do
      add_line "Image(systemName: selected#{group.split('_').map(&:capitalize).join} == \"#{id}\" ? \"largecircle.fill.circle\" : \"circle\")"
      add_modifier_line ".foregroundColor(.blue)"
      add_modifier_line ".onTapGesture {"
      indent do
        add_line "selected#{group.split('_').map(&:capitalize).join} = \"#{id}\""
        if @component['onclick']
          add_line "// TODO: Implement #{@component['onclick']} action"
        end
      end
      add_line "}"
      
      if @component['text']
        add_line "Text(\"#{@component['text']}\")"
      end
    end
    add_line "}"
    
    # 共通のモディファイアを適用
    apply_modifiers
    
    generated_code
  end
end