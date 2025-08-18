#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      # Generated code network image converter
      # Dynamic mode equivalent: Sources/SwiftJsonUI/Classes/SwiftUI/Dynamic/Converters/NetworkImageConverter.swift
      class NetworkImageConverter < BaseViewConverter
        def convert
          url = @component['src'] || ""
          
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
            
            # defaultImage
            if @component['defaultImage']
              add_line "defaultImage: \"#{@component['defaultImage']}\","
            end
            
            # errorImage
            if @component['errorImage']
              add_line "errorImage: \"#{@component['errorImage']}\","
            end
            
            # loadingImage
            if @component['loadingImage']
              add_line "loadingImage: \"#{@component['loadingImage']}\","
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