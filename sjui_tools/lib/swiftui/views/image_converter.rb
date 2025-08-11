#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
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
          
          # 共通のモディファイアを適用
          apply_modifiers
          
          generated_code
        end
        
        private
        
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