# frozen_string_literal: true

require_relative 'template_helper'
require_relative 'alignment_helper'
require_relative 'frame_helper'
require_relative 'color_helper'
require_relative 'spacing_helper'
require_relative 'modifier_helper'
require_relative '../binding/binding_handler_registry'

module SjuiTools
  module SwiftUI
    module Views
      class BaseViewConverter
        include TemplateHelper
        include AlignmentHelper
        include FrameHelper
        include ColorHelper
        include SpacingHelper
        include ModifierHelper
        
        attr_reader :state_variables
        
        def initialize(component, indent_level = 0, action_manager = nil, binding_registry = nil)
          @component = component
          @indent_level = indent_level
          @action_manager = action_manager
          @generated_code = []
          @state_variables = []
          @binding_registry = binding_registry || SjuiTools::SwiftUI::Binding::BindingHandlerRegistry.new
          @binding_handler = @binding_registry.get_handler(@component['type'] || 'View')
          
          # includeとvariables処理
          handle_include_and_variables
        end

        def convert
          raise NotImplementedError, "Subclasses must implement convert method"
        end

        protected
        
        # Get value with binding support
        def get_binding_value(key, default = nil)
          value = @component[key]
          @binding_handler.get_value(value, default)
        end
        
        # Check if a value is a binding expression
        def is_binding?(value)
          @binding_handler.is_binding?(value)
        end
        
        # Apply binding modifiers
        def apply_binding_modifiers
          modifiers = @binding_handler.process_bindings(@component)
          modifiers.each do |modifier|
            add_modifier_line modifier if modifier
          end
        end
        
        def handle_include_and_variables
          # include処理は専用のIncludeConverterで処理するため、
          # ここではメタデータのみを記録
          if @component['include']
            # includeがある場合は、IncludeConverterが処理することを示すコメントを追加
            add_line "// Component will be replaced by IncludeConverter"
            add_line "// include: #{@component['include']}"
            
            if @component['shared_data']
              add_line "// shared_data: #{@component['shared_data'].to_json}"
            end
            
            if @component['data']
              add_line "// data: #{@component['data'].to_json}"
            end
            
            if @component['variables']
              add_line "// variables: #{@component['variables'].to_json}"
            end
          end
        end

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
          # アライメント処理を先に適用
          apply_center_alignment
          apply_edge_alignment
          
          # サイズ制約とサイズの適用
          apply_frame_constraints
          apply_frame_size
          
          # 背景色（Rectangleの場合はfillで設定済みなのでスキップ）
          # enabled状態に応じて背景色を変更
          if @component['enabled'] == false && @component['disabledBackground']
            # 無効状態の背景色
            color = hex_to_swiftui_color(@component['disabledBackground'])
            add_modifier_line ".background(#{color})"
          elsif @component['background'] && !@skip_background
            processed_bg = process_template_value(@component['background'])
            if processed_bg.is_a?(Hash) && processed_bg[:template_var]
              add_modifier_line ".background(#{to_camel_case(processed_bg[:template_var])})"
            else
              color = hex_to_swiftui_color(@component['background'])
              add_modifier_line ".background(#{color})"
            end
          end
          
          # マージン（外側のスペース - SwiftUIではpaddingで実装）
          # 注: SwiftUIにはマージンの概念がないため、親ビューでpaddingとして扱う必要がある
          apply_margins
          
          # パディング（SwiftJsonUIの属性に対応）
          apply_padding
          
          # insetsとinsetHorizontalの処理
          apply_insets
          
          # コーナー半径
          if @component['cornerRadius']
            add_modifier_line ".cornerRadius(#{@component['cornerRadius'].to_i})"
          end
          
          # 透明度 (alphaとopacityの両方をサポート)
          if @component['alpha']
            add_modifier_line ".opacity(#{@component['alpha']})"
          elsif @component['opacity']
            add_modifier_line ".opacity(#{@component['opacity']})"
          end
          
          # visibility属性はVisibilityWrapperで処理するので、ここでは何もしない
          # The actual wrapping happens in the parent view converter
          
          # 影
          if @component['shadow']
            # shadowが詳細な設定を持つ場合
            if @component['shadow'].is_a?(Hash)
              radius = @component['shadow']['radius'] || 5
              x = @component['shadow']['offsetX'] || 0
              y = @component['shadow']['offsetY'] || 0
              color_hex = @component['shadow']['color']
              
              if color_hex
                color = hex_to_swiftui_color(color_hex)
                add_modifier_line ".shadow(color: #{color}, radius: #{radius}, x: #{x}, y: #{y})"
              else
                add_modifier_line ".shadow(radius: #{radius}, x: #{x}, y: #{y})"
              end
            else
              # shadowがbooleanまたはその他の場合
              add_modifier_line ".shadow(radius: 5)"
            end
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
              add_line "RoundedRectangle(cornerRadius: #{(@component['cornerRadius'] || 0).to_i})"
              add_modifier_line ".stroke(#{color}, lineWidth: #{@component['borderWidth'].to_i})"
            end
            add_line ")"
          end
          
          # オフセット（offsetX, offsetY）
          if @component['offsetX'] || @component['offsetY']
            offset_x = @component['offsetX'] || 0
            offset_y = @component['offsetY'] || 0
            add_modifier_line ".offset(x: #{offset_x}, y: #{offset_y})"
          end
          
          # 表示/非表示
          if @component['hidden'] == true
            add_modifier_line ".hidden()"
          end
          
          # safeAreaInsetPositions
          apply_safe_area_insets
          
          # disabled状態の処理
          if @component['enabled'] == false
            add_modifier_line ".disabled(true)"
          end
          
          # tagプロパティの適用（TabViewなどで使用）
          if @component['tag']
            add_modifier_line ".tag(#{@component['tag']})"
          end
          
          # classNameプロパティ（SwiftUIではスタイル識別子として記録）
          if @component['className']
            add_line "// className: #{@component['className']}"
          end
          
          # touchDisabledState（タッチ無効化状態）
          if @component['touchDisabledState']
            add_modifier_line ".allowsHitTesting(false)"
            add_line "// touchDisabledState applied"
          end
          
          # バインディング関連プロパティ（コメントとして記録）
          if @component['bindingScript']
            add_line "// bindingScript: #{@component['bindingScript']}"
          end
          if @component['binding_group']
            add_line "// binding_group: #{@component['binding_group']}"
          end
          if @component['binding_id']
            add_line "// binding_id: #{@component['binding_id']}"
          end
          if @component['shared_data']
            add_line "// shared_data: #{@component['shared_data']}"
          end
          
          # indexBelow（Z軸順序の指定）
          if @component['indexBelow']
            # indexBelowは指定した他のビューの下に配置することを意味する可能性
            # SwiftUIではzIndexを使用して相対的な前後関係を制御
            add_line "// indexBelow: #{@component['indexBelow']} - Place below specified view"
            # 数値の場合はzIndexとして使用、文字列の場合は他のビューIDを参照
            if @component['indexBelow'].to_s =~ /^\d+$/
              add_modifier_line ".zIndex(-#{@component['indexBelow'].to_i})"
            else
              add_line "// Reference to view ID: #{@component['indexBelow']}"
              add_modifier_line ".zIndex(-1)"  # デフォルトで背面に配置
            end
          end
          
          # クリックイベント (onclickとonClick両方をサポート)
          # ただし、Buttonの場合は既にactionで処理しているのでスキップ
          unless @component['type'] == 'Button'
            click_action = @component['onclick'] || @component['onClick']
            if click_action
              # enabled=falseの場合はクリックイベントを追加しない
              unless @component['enabled'] == false
                add_modifier_line ".onTapGesture {"
                indent do
                  # パラメータ付きメソッドの場合（例: "toggleMode:"）
                  if click_action.include?(':')
                    method_name = click_action.gsub(':', '')
                    add_line "viewModel.#{method_name}(self)"
                  else
                    # パラメータなしメソッドの場合
                    add_line "viewModel.#{click_action}()"
                  end
                end
                add_line "}"
              end
            end
          end
        end
        

        # ヘルパーメソッド
      end
    end
  end
end