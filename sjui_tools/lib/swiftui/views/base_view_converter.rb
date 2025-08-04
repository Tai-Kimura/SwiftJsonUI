# frozen_string_literal: true

require_relative 'template_helper'

module SjuiTools
  module SwiftUI
    module Views
      class BaseViewConverter
        include TemplateHelper
        
        attr_reader :state_variables
        
        def initialize(component, indent_level = 0, action_manager = nil)
          @component = component
          @indent_level = indent_level
          @action_manager = action_manager
          @generated_code = []
          @state_variables = []
        end

        def convert
          raise NotImplementedError, "Subclasses must implement convert method"
        end

        protected

        def add_line(line)
          @generated_code << ("    " * @indent_level + line)
        end

        def add_modifier_line(modifier)
          add_line "    #{modifier}"
        end

        def indent(&block)
          @indent_level += 1
          yield
          @indent_level -= 1
        end

        def generated_code
          @generated_code.join("\n")
        end

        # 共通のモディファイア適用メソッド
        def apply_modifiers
          # サイズ
          if @component['width'] || @component['height']
            # widthの処理
            processed_width = process_template_value(@component['width'])
            if processed_width.is_a?(Hash) && processed_width[:template_var]
              width_value = to_camel_case(processed_width[:template_var])
            else
              width_value = size_to_swiftui(@component['width'])
            end
            
            # heightの処理
            processed_height = process_template_value(@component['height'])
            if processed_height.is_a?(Hash) && processed_height[:template_var]
              height_value = to_camel_case(processed_height[:template_var])
            else
              height_value = size_to_swiftui(@component['height'])
            end
            
            # テンプレート変数の場合は型変換が必要
            if processed_width.is_a?(Hash) && processed_width[:template_var]
              width_param = "CGFloat(#{width_value})"
            else
              width_param = width_value
            end
            
            if processed_height.is_a?(Hash) && processed_height[:template_var]
              height_param = "CGFloat(#{height_value})"
            else
              height_param = height_value
            end
            
            if width_value && height_value
              add_modifier_line ".frame(width: #{width_param}, height: #{height_param})"
            elsif width_value
              if width_value == '.infinity'
                add_modifier_line ".frame(maxWidth: #{width_param})"
              else
                add_modifier_line ".frame(width: #{width_param})"
              end
            elsif height_value
              add_modifier_line ".frame(height: #{height_param})"
            end
          end
          
          # 背景色
          if @component['background']
            processed_bg = process_template_value(@component['background'])
            if processed_bg.is_a?(Hash) && processed_bg[:template_var]
              add_modifier_line ".background(#{to_camel_case(processed_bg[:template_var])})"
            else
              color = hex_to_swiftui_color(@component['background'])
              add_modifier_line ".background(#{color})"
            end
          end
          
          # パディング（SwiftJsonUIの属性に対応）
          if @component['padding'] || @component['paddings']
            padding = @component['padding'] || @component['paddings']
            if padding.is_a?(Array)
              case padding.length
              when 1
                add_modifier_line ".padding(#{padding[0]})"
              when 2
                # 縦横のパディング
                add_modifier_line ".padding(.horizontal, #{padding[1]})"
                add_modifier_line ".padding(.vertical, #{padding[0]})"
              when 4
                # 上、右、下、左の順
                add_modifier_line ".padding(.top, #{padding[0]})"
                add_modifier_line ".padding(.trailing, #{padding[1]})"
                add_modifier_line ".padding(.bottom, #{padding[2]})"
                add_modifier_line ".padding(.leading, #{padding[3]})"
              end
            else
              add_modifier_line ".padding(#{padding})"
            end
          end
          
          # コーナー半径
          if @component['cornerRadius']
            add_modifier_line ".cornerRadius(#{@component['cornerRadius']})"
          end
          
          # 透明度
          if @component['alpha']
            add_modifier_line ".opacity(#{@component['alpha']})"
          end
          
          # 影
          if @component['shadow']
            add_modifier_line ".shadow(radius: 5)"
          end
          
          # クリップ
          if @component['clipToBounds']
            add_modifier_line ".clipped()"
          end
          
          # ボーダー
          if @component['borderWidth'] && @component['borderColor']
            color = hex_to_swiftui_color(@component['borderColor'])
            add_modifier_line ".overlay("
            indent do
              add_line "RoundedRectangle(cornerRadius: #{@component['cornerRadius'] || 0})"
              add_modifier_line ".stroke(#{color}, lineWidth: #{@component['borderWidth']})"
            end
            add_line ")"
          end
          
          # 表示/非表示
          if @component['hidden'] == true
            add_modifier_line ".hidden()"
          end
          
          # クリックイベント (onclickとonClick両方をサポート)
          click_action = @component['onclick'] || @component['onClick']
          if click_action
            add_modifier_line ".onTapGesture {"
            indent do
              if @action_manager
                handler_name = @action_manager.register_action(click_action, 'view')
                add_line "#{handler_name}()"
              else
                add_line "// TODO: Handle #{click_action} action"
              end
            end
            add_line "}"
          end
        end

        # ヘルパーメソッド
        def size_to_swiftui(size)
          return nil if size.nil?
          
          case size
          when 'matchParent'
            '.infinity'
          when 'wrapContent'
            nil  # SwiftUIのデフォルト動作
          when Integer, Float
            size.to_s
          when String
            if size.match?(/^\d+$/)
              size
            else
              # その他の文字列はそのまま返す（変数名など）
              size
            end
          else
            size.to_s
          end
        end

        def hex_to_swiftui_color(hex)
          return "Color.clear" if hex.nil? || hex.empty?
          
          # 16進数カラーコードの処理
          if hex.start_with?('#')
            hex = hex[1..-1]
          end
          
          # 6桁の16進数に変換
          hex = hex.upcase
          
          if hex.length == 6
            r = hex[0..1].to_i(16) / 255.0
            g = hex[2..3].to_i(16) / 255.0
            b = hex[4..5].to_i(16) / 255.0
            "Color(red: #{r}, green: #{g}, blue: #{b})"
          else
            "Color.black"  # デフォルト
          end
        end
      end
    end
  end
end