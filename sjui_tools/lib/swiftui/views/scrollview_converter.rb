#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class ScrollViewConverter < BaseViewConverter
        def initialize(component, indent_level = 0, action_manager = nil, converter_factory = nil, view_registry = nil, binding_registry = nil)
          super(component, indent_level, action_manager, binding_registry)
          @converter_factory = converter_factory
          @view_registry = view_registry
        end

        def convert
          child_data = @component['child'] || []
          # childが単一要素の場合は配列に変換
          children = child_data.is_a?(Array) ? child_data : [child_data]
          
          # スクロール方向の判定
          # horizontalScroll属性、orientation属性、またはchild要素の配置から判定
          orientation = @component['orientation']
          horizontal_scroll = @component['horizontalScroll']
          
          # 子要素が1つでView/SafeAreaViewの場合、その orientation を確認
          if children.length == 1 && ['View', 'SafeAreaView'].include?(children.first['type'])
            child_orientation = children.first['orientation']
            orientation ||= child_orientation
          end
          
          # スクロール軸の設定
          if horizontal_scroll || orientation == 'horizontal'
            axes = '.horizontal'
            stack_type = 'HStack'
          else
            # デフォルトは垂直スクロール
            axes = '.vertical'
            stack_type = 'VStack'
          end
          
          # インジケーターの表示設定
          show_indicators = if orientation == 'horizontal'
            @component['showsHorizontalScrollIndicator'] != false
          else
            @component['showsVerticalScrollIndicator'] != false
          end
          
          # AdvancedKeyboardAvoidingScrollViewを使用（キーボードとSelectBox対応）
          add_line "AdvancedKeyboardAvoidingScrollView(#{axes}, showsIndicators: #{show_indicators}) {"
          
          indent do
            if children.length == 1
              if @converter_factory
                child_converter = @converter_factory.create_converter(children.first, @indent_level, @action_manager, @converter_factory, @view_registry)
                child_code = child_converter.convert
                child_code.split("\n").each { |line| @generated_code << line }
                
                # Propagate state variables
                if child_converter.respond_to?(:state_variables) && child_converter.state_variables
                  @state_variables.concat(child_converter.state_variables)
                end
              end
            else
              add_line "#{stack_type}(spacing: 0) {"
              indent do
                children.each do |child|
                  if @converter_factory
                    child_converter = @converter_factory.create_converter(child, @indent_level, @action_manager, @converter_factory, @view_registry)
                    child_code = child_converter.convert
                    child_code.split("\n").each { |line| @generated_code << line }
                    
                    # Propagate state variables
                    if child_converter.respond_to?(:state_variables) && child_converter.state_variables
                      @state_variables.concat(child_converter.state_variables)
                    end
                  end
                end
              end
              add_line "}"
            end
          end
          add_line "}"
          
          # scrollEnabled
          if @component['scrollEnabled'] == false
            add_modifier_line ".disabled(true)"
          end
          
          # bounces
          if @component['bounces'] == false
            add_modifier_line "// Note: bounce behavior cannot be disabled in SwiftUI"
          end
          
          # contentInsetAdjustmentBehavior
          if @component['contentInsetAdjustmentBehavior']
            case @component['contentInsetAdjustmentBehavior']
            when 'never'
              add_modifier_line ".ignoresSafeArea()"
            when 'scrollableAxes'
              add_modifier_line ".ignoresSafeArea(edges: .horizontal)"
            when 'always', 'automatic'
              # デフォルトの動作
            else
              add_line "// contentInsetAdjustmentBehavior: #{@component['contentInsetAdjustmentBehavior']}"
            end
          end
          
          # paging プロパティの処理
          if @component['paging'] == true || @component['paging'] == 'true'
            # iOS 17+ では.scrollTargetBehavior(.paging)が使える
            add_modifier_line ".scrollTargetBehavior(.paging)"
            add_line "// Note: Paging requires iOS 17+"
          end
          
          # maxZoom プロパティの処理（ズーム可能なScrollView）
          if @component['maxZoom']
            add_modifier_line ".scaleEffect(1.0)"  # デフォルトスケール
            add_line "// maxZoom: #{@component['maxZoom']} - Consider using MagnificationGesture"
            add_modifier_line ".gesture("
            indent do
              add_line "MagnificationGesture()"
              add_modifier_line ".onChanged { value in"
              indent do
                add_line "// Scale content based on gesture"
                add_line "// Maximum zoom: #{@component['maxZoom']}"
              end
              add_line "}"
            end
            add_line ")"
          end
          
          # AdvancedKeyboardAvoidingScrollViewは自動的に両方の回避機能を持つため、
          # 追加のモディファイアは不要
          
          # 共通のモディファイアを適用
          apply_modifiers
          
          generated_code
        end
      end
    end
  end
end