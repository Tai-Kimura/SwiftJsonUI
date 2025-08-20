#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      # Generated code image converter
      # Dynamic mode equivalent: Sources/SwiftJsonUI/Classes/SwiftUI/Dynamic/Converters/ImageViewConverter.swift
      class ImageConverter < BaseViewConverter
        def convert
          # srcName優先（srcNameはアセット名を直接指定）
          if @component['srcName']
            add_line "Image(\"#{@component['srcName']}\")"
          elsif @component['src']
            processed_src = process_template_value(@component['src'])
            if processed_src.is_a?(Hash) && processed_src[:template_var]
              # テンプレート変数の場合
              add_line "Image(#{to_camel_case(processed_src[:template_var])})"
            else
              # 通常の画像名
              add_line "Image(\"#{@component['src']}\")"
            end
          elsif @component['defaultImage']
            # defaultImageが指定されている場合はそれを使用
            add_line "Image(\"#{@component['defaultImage']}\")"
          else
            # デフォルトのシステムイメージ
            add_line "Image(systemName: \"photo\")"
          end
          
          add_modifier_line ".resizable()"
          
          # contentMode
          if @component['contentMode']
            content_mode = map_content_mode(@component['contentMode'])
            add_modifier_line ".aspectRatio(contentMode: #{content_mode})"
          else
            add_modifier_line ".aspectRatio(contentMode: .fit)"
          end
          
          # CircleImageの場合
          if @component['type'] == 'CircleImage'
            add_modifier_line ".clipShape(Circle())"
          end
          
          # onSrcプロパティ（画像読み込み完了時のコールバック）
          if @component['onSrc']
            add_line "// onSrc: #{@component['onSrc']} - Image loaded callback"
            add_modifier_line ".onAppear {"
            indent do
              add_line "// Call #{@component['onSrc']} when image appears"
              if @component['onSrc'].include?(':')
                method_name = @component['onSrc'].gsub(':', '')
                add_line "viewModel.#{method_name}(self)"
              else
                add_line "viewModel.#{@component['onSrc']}()"
              end
            end
            add_line "}"
          end
          
          # canTap & onclick
          if @component['canTap'] && @component['onclick'] && @action_manager
            handler_name = @action_manager.register_action(@component['onclick'], 'image')
            add_modifier_line ".onTapGesture {"
            indent do
              if @component['onclick'].end_with?(':')
                add_line "viewModel.#{handler_name}(self)"
              else
                add_line "viewModel.#{handler_name}()"
              end
            end
            add_line "}"
          elsif @component['canTap'] && @component['onclick']
            add_modifier_line ".onTapGesture {"
            indent do
              add_line "// TODO: Implement #{@component['onclick']} action"
            end
            add_line "}"
          end
          
          # Apply padding (internal spacing)
          apply_padding
          
          # Apply background and corner radius
          if @component['background']
            color = hex_to_swiftui_color(@component['background'])
            add_modifier_line ".background(#{color})"
          end
          
          if @component['cornerRadius']
            add_modifier_line ".cornerRadius(#{@component['cornerRadius'].to_i})"
          end
          
          # Apply margins (external spacing)
          apply_margins
          
          # Apply other modifiers (opacity, hidden, etc.)
          apply_other_modifiers
          
          generated_code
        end
        
        private
        
        def apply_other_modifiers
          # Apply opacity
          if @component['alpha']
            add_modifier_line ".opacity(#{@component['alpha']})"
          elsif @component['opacity']
            add_modifier_line ".opacity(#{@component['opacity']})"
          end
          
          # Apply hidden
          if @component['hidden'] == true
            add_modifier_line ".hidden()"
          end
        end
        
        def map_content_mode(mode)
          case mode
          when 'AspectFill', 'aspectFill'
            '.fill'
          when 'AspectFit', 'aspectFit'
            '.fit'
          when 'center'
            '.fit'  # SwiftUIには直接的なcenterモードがないため
          else
            '.fit'
          end
        end
      end
    end
  end
end