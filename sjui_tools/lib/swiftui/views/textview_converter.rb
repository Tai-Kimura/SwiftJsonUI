#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class TextViewConverter < BaseViewConverter
        def convert
          id = @component['id'] || 'textEditor'
          
          # Create @State variable name
          state_var = "#{id}Text"
          
          # Add state variable to requirements
          add_state_variable(state_var, "String", '""')
          
          # TextViewWithPlaceholderを使用
          add_line "TextViewWithPlaceholder("
          indent do
            add_line "text: $viewModel.#{state_var},"
            
            # hint (placeholder)
            if @component['hint']
              # Escape newlines in hint text
              escaped_hint = @component['hint'].gsub("\n", "\\n")
              add_line "hint: \"#{escaped_hint}\","
            end
            
            # hintAttributes の処理
            if @component['hintAttributes']
              # hintAttributesからhintColorとhintFontを取得
              hint_attrs = @component['hintAttributes']
              
              if hint_attrs['fontColor'] || hint_attrs['color']
                color = hex_to_swiftui_color(hint_attrs['fontColor'] || hint_attrs['color'])
                add_line "hintColor: #{color},"
              elsif @component['hintColor']
                # 個別のhintColor属性も引き続きサポート
                color = hex_to_swiftui_color(@component['hintColor'])
                add_line "hintColor: #{color},"
              end
              
              if hint_attrs['font']
                add_line "hintFont: \"#{hint_attrs['font']}\","
              elsif @component['hintFont']
                # 個別のhintFont属性も引き続きサポート
                add_line "hintFont: \"#{@component['hintFont']}\","
              end
              
              # その他のhintAttributesはコメントとして記録
              add_line "// hintAttributes: #{hint_attrs.to_json}"
            else
              # hintColor (個別属性)
              if @component['hintColor']
                color = hex_to_swiftui_color(@component['hintColor'])
                add_line "hintColor: #{color},"
              end
              
              # hintFont (個別属性)
              if @component['hintFont']
                add_line "hintFont: \"#{@component['hintFont']}\","
              end
            end
            
            # hideOnFocused
            if @component['hideOnFocused'] == false
              add_line "hideOnFocused: false,"
            end
            
            # fontSize
            if @component['fontSize']
              add_line "fontSize: #{@component['fontSize']},"
            end
            
            # fontColor
            if @component['fontColor']
              color = hex_to_swiftui_color(@component['fontColor'])
              add_line "fontColor: #{color},"
            end
            
            # font
            if @component['font']
              add_line "fontName: \"#{@component['font']}\","
            end
            
            # background
            if @component['background']
              bg_color = hex_to_swiftui_color(@component['background'])
              add_line "backgroundColor: #{bg_color},"
            end
            
            # cornerRadius
            if @component['cornerRadius']
              add_line "cornerRadius: #{@component['cornerRadius']},"
            end
            
            # containerInset
            if @component['containerInset']
              inset = @component['containerInset']
              if inset.is_a?(Array)
                case inset.length
                when 1
                  add_line "containerInset: EdgeInsets(top: #{inset[0]}, leading: #{inset[0]}, bottom: #{inset[0]}, trailing: #{inset[0]}),"
                when 2
                  add_line "containerInset: EdgeInsets(top: #{inset[0]}, leading: #{inset[1]}, bottom: #{inset[0]}, trailing: #{inset[1]}),"
                when 4
                  add_line "containerInset: EdgeInsets(top: #{inset[0]}, leading: #{inset[1]}, bottom: #{inset[2]}, trailing: #{inset[3]}),"
                end
              else
                add_line "containerInset: EdgeInsets(top: #{inset}, leading: #{inset}, bottom: #{inset}, trailing: #{inset}),"
              end
            end
            
            # flexible
            if @component['flexible'] == true
              add_line "flexible: true,"
            end
            
            # minHeight
            if @component['minHeight']
              add_line "minHeight: #{@component['minHeight']},"
            end
            
            # maxHeight
            if @component['maxHeight']
              add_line "maxHeight: #{@component['maxHeight']}"
            else
              # 最後のカンマを削除
              if @generated_code.last.end_with?(',')
                @generated_code[-1] = @generated_code.last.chomp(',')
              end
            end
          end
          add_line ")"
          
          # 共通のモディファイア（frame, margin等）
          # flexibleがtrueの場合はframeの高さ指定を無視
          if @component['flexible'] == true
            # flexible時はheightを除外してモディファイアを適用
            original_height = @component['height']
            @component.delete('height')
            apply_modifiers
            @component['height'] = original_height if original_height
          else
            apply_modifiers
          end
          
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