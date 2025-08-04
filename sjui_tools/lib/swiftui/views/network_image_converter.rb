#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class NetworkImageConverter < BaseViewConverter
        def convert
          url = @component['url'] || ""
          
          # NetworkImageを使用
          add_line "NetworkImage("
          indent do
            # URL
            processed_url = process_template_value(url)
            if processed_url.is_a?(Hash) && processed_url[:template_var]
              add_line "url: #{to_camel_case(processed_url[:template_var])},"
            else
              add_line "url: \"#{url}\","
            end
            
            # プレースホルダー
            if @component['placeholder']
              add_line "placeholder: \"#{@component['placeholder']}\","
            end
            
            # contentMode
            if @component['contentMode']
              content_mode = map_content_mode_enum(@component['contentMode'])
              add_line "contentMode: #{content_mode},"
            end
            
            # renderingMode
            if @component['renderingMode']
              rendering_mode = map_rendering_mode(@component['renderingMode'])
              add_line "renderingMode: #{rendering_mode},"
            end
            
            # ヘッダー
            if @component['headers']
              add_line "headers: ["
              indent do
                @component['headers'].each_with_index do |(key, value), index|
                  comma = index < @component['headers'].length - 1 ? "," : ""
                  add_line "\"#{key}\": \"#{value}\"#{comma}"
                end
              end
              add_line "]"
            else
              # 最後のカンマを削除
              if @generated_code.last.end_with?(',')
                @generated_code[-1] = @generated_code.last.chomp(',')
              end
            end
          end
          add_line ")"
          
          # 共通のモディファイアを適用
          apply_modifiers
          
          generated_code
        end
        
        private
        
        def map_content_mode_enum(mode)
          case mode
          when 'AspectFill', 'aspectFill'
            '.fill'
          when 'AspectFit', 'aspectFit'
            '.fit'
          when 'center', 'Center'
            '.center'
          else
            '.fit'
          end
        end
        
        def map_rendering_mode(mode)
          case mode
          when 'template', 'Template'
            '.template'
          when 'original', 'Original'
            '.original'
          else
            'nil'
          end
        end
      end
    end
  end
end