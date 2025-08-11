# frozen_string_literal: true

require_relative 'template_helper'
require_relative 'alignment_helper'
require_relative '../binding/binding_handler_registry'

module SjuiTools
  module SwiftUI
    module Views
      class BaseViewConverter
        include TemplateHelper
        include AlignmentHelper
        
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
          # include処理（JSONの読み込みと変数置換）
          if @component['include']
            add_line "// include: #{@component['include']}"
            if @component['variables']
              add_line "// variables: #{@component['variables'].to_json}"
            end
            # 実際のinclude処理はビルド時のプリプロセッサで行う必要がある
            # ここではコメントとして記録
          elsif @component['variables']
            # variablesのみの場合もコメントとして記録
            add_line "// variables: #{@component['variables'].to_json}"
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
          
          # サイズ制約（minWidth, maxWidth, minHeight, maxHeight）
          if @component['minWidth'] || @component['maxWidth'] || @component['minHeight'] || @component['maxHeight']
            min_width = @component['minWidth']
            max_width = @component['maxWidth']
            min_height = @component['minHeight'] 
            max_height = @component['maxHeight']
            
            frame_params = []
            frame_params << "minWidth: #{min_width}" if min_width
            frame_params << "maxWidth: #{max_width == 'matchParent' ? '.infinity' : max_width}" if max_width
            frame_params << "minHeight: #{min_height}" if min_height
            frame_params << "maxHeight: #{max_height == 'matchParent' ? '.infinity' : max_height}" if max_height
            
            if frame_params.any?
              add_modifier_line ".frame(#{frame_params.join(', ')})"
            end
          end
          
          # サイズ
          if @component['width'] || @component['height']
            # weightがある場合、width: 0 or height: 0は無視する
            should_ignore_width = (@component['width'] == 0 || @component['width'] == '0') && 
                                 (@component['weight'] || @component['widthWeight'])
            should_ignore_height = (@component['height'] == 0 || @component['height'] == '0') && 
                                  (@component['weight'] || @component['heightWeight'])
            
            # widthの処理
            if !should_ignore_width
              processed_width = process_template_value(@component['width'])
              if processed_width.is_a?(Hash) && processed_width[:template_var]
                width_value = to_camel_case(processed_width[:template_var])
              else
                width_value = size_to_swiftui(@component['width'])
              end
            else
              width_value = nil
            end
            
            # heightの処理
            if !should_ignore_height
              processed_height = process_template_value(@component['height'])
              if processed_height.is_a?(Hash) && processed_height[:template_var]
                height_value = to_camel_case(processed_height[:template_var])
              else
                height_value = size_to_swiftui(@component['height'])
              end
            else
              height_value = nil
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
              # Check if either dimension is .infinity
              if width_value == '.infinity' && height_value == '.infinity'
                add_modifier_line ".frame(maxWidth: #{width_param}, maxHeight: #{height_param})"
              elsif width_value == '.infinity'
                # Split into two frame calls for maxWidth with fixed height
                add_modifier_line ".frame(maxWidth: #{width_param})"
                add_modifier_line ".frame(height: #{height_param})"
              elsif height_value == '.infinity'
                # Split into two frame calls for fixed width with maxHeight
                add_modifier_line ".frame(width: #{width_param})"
                add_modifier_line ".frame(maxHeight: #{height_param})"
              else
                add_modifier_line ".frame(width: #{width_param}, height: #{height_param})"
              end
            elsif width_value
              if width_value == '.infinity'
                add_modifier_line ".frame(maxWidth: #{width_param})"
              else
                add_modifier_line ".frame(width: #{width_param})"
              end
            elsif height_value
              if height_value == '.infinity'
                add_modifier_line ".frame(maxHeight: #{height_param})"
              else
                add_modifier_line ".frame(height: #{height_param})"
              end
            end
          end
          
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
          if @component['padding'] || @component['paddings']
            padding = @component['padding'] || @component['paddings']
            # Ensure padding is converted to proper format
            if padding.is_a?(Array)
              case padding.length
              when 1
                add_modifier_line ".padding(#{padding[0].to_i})"
              when 2
                # 縦横のパディング
                add_modifier_line ".padding(.horizontal, #{padding[1].to_i})"
                add_modifier_line ".padding(.vertical, #{padding[0].to_i})"
              when 4
                # 上、右、下、左の順
                add_modifier_line ".padding(.top, #{padding[0].to_i})"
                add_modifier_line ".padding(.trailing, #{padding[1].to_i})"
                add_modifier_line ".padding(.bottom, #{padding[2].to_i})"
                add_modifier_line ".padding(.leading, #{padding[3].to_i})"
              end
            else
              add_modifier_line ".padding(#{padding.to_i})"
            end
          end
          
          # 個別のパディング設定（leftPadding, rightPadding, paddingLeft など）
          # paddingLeft と leftPadding の両方をサポート
          left_pad = @component['leftPadding'] || @component['paddingLeft']
          right_pad = @component['rightPadding'] || @component['paddingRight']
          top_pad = @component['topPadding'] || @component['paddingTop']
          bottom_pad = @component['bottomPadding'] || @component['paddingBottom']
          
          if left_pad
            add_modifier_line ".padding(.leading, #{left_pad.to_i})"
          end
          if right_pad
            add_modifier_line ".padding(.trailing, #{right_pad.to_i})"
          end
          if top_pad
            add_modifier_line ".padding(.top, #{top_pad.to_i})"
          end
          if bottom_pad
            add_modifier_line ".padding(.bottom, #{bottom_pad.to_i})"
          end
          
          # insets プロパティ（パディングの別形式）
          if @component['insets']
            insets = @component['insets']
            if insets.is_a?(Array)
              case insets.length
              when 1
                add_modifier_line ".padding(#{insets[0].to_i})"
              when 2
                # 縦横のinsets
                add_modifier_line ".padding(.vertical, #{insets[0].to_i})"
                add_modifier_line ".padding(.horizontal, #{insets[1].to_i})"
              when 4
                # 上、右、下、左の順
                add_modifier_line ".padding(.top, #{insets[0].to_i})"
                add_modifier_line ".padding(.trailing, #{insets[1].to_i})"
                add_modifier_line ".padding(.bottom, #{insets[2].to_i})"
                add_modifier_line ".padding(.leading, #{insets[3].to_i})"
              end
            else
              add_modifier_line ".padding(#{insets.to_i})"
            end
          end
          
          # insetHorizontal プロパティ
          if @component['insetHorizontal']
            add_modifier_line ".padding(.horizontal, #{@component['insetHorizontal'].to_i})"
          end
          
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
          if @component['safeAreaInsetPositions']
            positions = @component['safeAreaInsetPositions']
            if positions.is_a?(Array)
              # 配列の場合、各エッジを処理
              edges = []
              edges << '.top' if positions.include?('top')
              edges << '.bottom' if positions.include?('bottom')
              edges << '.leading' if positions.include?('leading') || positions.include?('left')
              edges << '.trailing' if positions.include?('trailing') || positions.include?('right')
              
              if edges.any?
                add_modifier_line ".ignoresSafeArea(.all, edges: [#{edges.join(', ')}])"
              end
            elsif positions == 'all'
              add_modifier_line ".ignoresSafeArea()"
            elsif positions == 'none'
              # デフォルトでセーフエリアを尊重
            else
              add_line "// safeAreaInsetPositions: #{positions}"
            end
          end
          
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
        
        # マージンを適用（SwiftUIではGroup内でpaddingとして実装）
        def apply_margins
          left_margin = @component['leftMargin']
          right_margin = @component['rightMargin']
          top_margin = @component['topMargin']
          bottom_margin = @component['bottomMargin']
          margins = @component['margins']
          
          # marginsが配列で指定されている場合
          if margins
            if margins.is_a?(Array)
              case margins.length
              when 1
                # 全方向同じマージン
                add_modifier_line ".padding(.all, #{margins[0].to_i})"
              when 2
                # 縦横のマージン
                add_modifier_line ".padding(.vertical, #{margins[0].to_i})"
                add_modifier_line ".padding(.horizontal, #{margins[1].to_i})"
              when 4
                # 上、右、下、左の順
                add_modifier_line ".padding(.top, #{margins[0].to_i})"
                add_modifier_line ".padding(.trailing, #{margins[1].to_i})"
                add_modifier_line ".padding(.bottom, #{margins[2].to_i})"
                add_modifier_line ".padding(.leading, #{margins[3].to_i})"
              end
            else
              add_modifier_line ".padding(.all, #{margins.to_i})"
            end
          else
            # 個別のマージン設定
            if top_margin
              add_modifier_line ".padding(.top, #{top_margin.to_i})"
            end
            if bottom_margin
              add_modifier_line ".padding(.bottom, #{bottom_margin.to_i})"
            end
            if left_margin
              add_modifier_line ".padding(.leading, #{left_margin.to_i})"
            end
            if right_margin
              add_modifier_line ".padding(.trailing, #{right_margin.to_i})"
            end
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
          
          hex = hex.upcase
          
          if hex.length == 6
            # 6桁の16進数（RGB）
            r = hex[0..1].to_i(16) / 255.0
            g = hex[2..3].to_i(16) / 255.0
            b = hex[4..5].to_i(16) / 255.0
            "Color(red: #{r}, green: #{g}, blue: #{b})"
          elsif hex.length == 8
            # 8桁の16進数（ARGB または RGBA）
            # SwiftJsonUIは通常ARGBフォーマットを使用
            a = hex[0..1].to_i(16) / 255.0
            r = hex[2..3].to_i(16) / 255.0
            g = hex[4..5].to_i(16) / 255.0
            b = hex[6..7].to_i(16) / 255.0
            "Color(red: #{r}, green: #{g}, blue: #{b}, opacity: #{a})"
          else
            "Color.black"  # デフォルト
          end
        end
        
        def gradient_direction_to_swiftui(direction)
          # directionプロパティをSwiftUIのグラデーション方向に変換
          case direction
          when 'vertical', 'top_bottom'
            'startPoint: .top, endPoint: .bottom'
          when 'horizontal', 'left_right'
            'startPoint: .leading, endPoint: .trailing'
          when 'bottom_top'
            'startPoint: .bottom, endPoint: .top'
          when 'right_left'
            'startPoint: .trailing, endPoint: .leading'
          when 'topLeft_bottomRight', 'diagonal'
            'startPoint: .topLeading, endPoint: .bottomTrailing'
          when 'topRight_bottomLeft'
            'startPoint: .topTrailing, endPoint: .bottomLeading'
          when 'bottomLeft_topRight'
            'startPoint: .bottomLeading, endPoint: .topTrailing'
          when 'bottomRight_topLeft'
            'startPoint: .bottomTrailing, endPoint: .topLeading'
          else
            'startPoint: .top, endPoint: .bottom'  # デフォルト
          end
        end
      end
    end
  end
end