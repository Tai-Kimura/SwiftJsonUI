#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class SelectBoxConverter < BaseViewConverter
        def convert
          id = @component['id'] || 'selectBox'
          prompt = @component['prompt']
          selectItemType = @component['selectItemType'] || 'Normal'
          items = @component['items'] || []
          
          # SelectBoxViewを使用
          add_line "SelectBoxView("
          indent do
            add_line "id: \"#{id}\","
            
            if prompt
              add_line "prompt: \"#{prompt}\","
            end
            
            if @component['fontSize']
              add_line "fontSize: #{@component['fontSize']},"
            end
            
            if @component['fontColor']
              color = hex_to_swiftui_color(@component['fontColor'])
              add_line "fontColor: #{color},"
            end
            
            if @component['background']
              bg_color = hex_to_swiftui_color(@component['background'])
              add_line "backgroundColor: #{bg_color},"
            end
            
            if @component['cornerRadius']
              add_line "cornerRadius: #{@component['cornerRadius']},"
            end
            
            # selectItemType
            case selectItemType
            when 'Date'
              add_line "selectItemType: .date,"
              
              # datePickerMode
              if @component['datePickerMode']
                case @component['datePickerMode']
                when 'time'
                  add_line "datePickerMode: .time,"
                when 'datetime', 'dateAndTime'
                  add_line "datePickerMode: .dateTime,"
                else
                  add_line "datePickerMode: .date,"
                end
              end
              
              # datePickerStyle
              if @component['datePickerStyle']
                case @component['datePickerStyle']
                when 'automatic'
                  add_line "datePickerStyle: .automatic,"
                when 'compact'
                  add_line "datePickerStyle: .compact,"
                when 'graphical', 'inline'  # SwiftJsonUIのinlineはSwiftUIのgraphicalにマッピング
                  add_line "datePickerStyle: .graphical,"
                else # 'wheels' or default
                  add_line "datePickerStyle: .wheel,"
                end
              end
              
              # dateStringFormat
              if @component['dateStringFormat']
                add_line "dateStringFormat: \"#{@component['dateStringFormat']}\","
              end
              
              # minimumDate
              if @component['minimumDate']
                add_line "minimumDate: \"#{@component['minimumDate']}\".toDate(format: \"yyyy-MM-dd\") ?? Date(),"
              end
              
              # maximumDate  
              if @component['maximumDate']
                add_line "maximumDate: \"#{@component['maximumDate']}\".toDate(format: \"yyyy-MM-dd\") ?? Date(),"
              end
              
              # Note: minuteInterval and selectedDate are not supported by SelectBoxView
              # These are managed internally or not applicable
              
              # Remove trailing comma from last parameter
              @generated_code[-1] = @generated_code[-1].chomp(',')
            else
              add_line "selectItemType: .normal,"
              
              # Note: SelectBoxView manages its own state internally
              # selectedItem binding is not supported in the current implementation
              
              # items配列の処理
              if items.is_a?(String) && items.start_with?('@{') && items.end_with?('}')
                # テンプレート変数の場合
                add_line "items: Array(#{to_camel_case(items[2..-2])})"
              elsif items.is_a?(Array) && items.any?
                # 静的配列の場合
                add_line "items: [#{items.map { |item| "\"#{item}\"" }.join(", ")}]"
              else
                add_line "items: []"
              end
            end
          end
          add_line ")"
          
          # SelectBoxView handles padding/background/cornerRadius internally
          # Only apply frame, border, and margins here
          # Corresponding to Dynamic mode: SelectBoxConverter.swift
          
          # Apply frame modifiers
          apply_frame_constraints
          apply_frame_size
          
          # Note: padding, background and cornerRadius are handled internally by SelectBoxView
          
          # Apply border (after component's internal cornerRadius)
          if @component['borderWidth'] && @component['borderColor']
            color = hex_to_swiftui_color(@component['borderColor'])
            add_modifier_line ".overlay("
            indent do
              add_line "RoundedRectangle(cornerRadius: #{(@component['cornerRadius'] || 8).to_i})"
              add_modifier_line ".stroke(#{color}, lineWidth: #{@component['borderWidth'].to_i})"
            end
            add_line ")"
          end
          
          # Apply margins (external spacing)
          apply_margins
          
          # Apply other modifiers
          if @component['alpha']
            add_modifier_line ".opacity(#{@component['alpha']})"
          elsif @component['opacity']
            add_modifier_line ".opacity(#{@component['opacity']})"
          end
          
          if @component['hidden'] == true
            add_modifier_line ".hidden()"
          end
          
          generated_code
        end
      end
    end
  end
end