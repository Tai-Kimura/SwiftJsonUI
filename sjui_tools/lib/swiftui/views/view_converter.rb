#!/usr/bin/env ruby

require_relative 'base_view_converter'
require_relative 'stack_alignment_helper'
require_relative 'relative_positioning_helper'
require_relative 'child_rendering_helper'
require_relative 'modifier_helper'
require_relative 'positioning_helper'
require_relative 'alignment_wrapper_helper'
require_relative 'visibility_helper'

module SjuiTools
  module SwiftUI
    module Views
      class ViewConverter < BaseViewConverter
        include StackAlignmentHelper
        include RelativePositioningHelper
        include ChildRenderingHelper
        include ModifierHelper
        include PositioningHelper
        include AlignmentWrapperHelper
        include VisibilityHelper
        def initialize(component, indent_level = 0, action_manager = nil, converter_factory = nil, view_registry = nil, binding_registry = nil)
          super(component, indent_level, action_manager, binding_registry)
          @converter_factory = converter_factory
          @view_registry = view_registry || SjuiTools::SwiftUI::ViewRegistry.new
        end
        
        def convert
          # ビューレジストリに自身を登録
          if @component['id'] && @view_registry
            @view_registry.register_view(@component['id'], @component)
          end
          
          child_data = @component['child'] || []
          # childが単一要素の場合は配列に変換
          children = child_data.is_a?(Array) ? child_data : [child_data]
          # Filter out data declarations - only if child is a Hash
          children = children.reject { |child| child.is_a?(Hash) && child['data'] }
          
          # 子ビューもレジストリに登録
          children.each do |child|
            if child.is_a?(Hash) && child['id'] && @view_registry
              @view_registry.register_view(child['id'], child)
            end
          end
          
          # 相対配置が必要かチェック
          @needs_relative_positioning = has_relative_positioning?(children)
          @has_view_ids = children.any? { |child| child.is_a?(Hash) && child['id'] }
          
          if children.empty?
            # 子要素がない場合
            # backgroundが設定されている場合はRectangleを使用（dividerなど）
            if @component['background']
              add_line "Rectangle()"
              add_modifier_line ".fill(#{hex_to_swiftui_color(@component['background'])})"
              # Rectangleの場合はbackgroundを適用しない
              @skip_background = true
            else
              add_line "EmptyView()"
            end
          else
            # 複数の子要素がある場合
            # orientationが指定されていない場合はZStackを使用
            orientation = @component['orientation']
            
            # 子要素のweightをチェック
            has_weights = children.any? { |child| 
              (child['weight'] || child['widthWeight'] || child['heightWeight'] || 0).to_f > 0 
            }
            
            if has_weights && (orientation == 'horizontal' || orientation == 'vertical')
              # weightがある場合はWeightedStack用の子要素を構築
              weighted_children = []
              children.each do |child|
                weight = (child['weight'] || child['widthWeight'] || child['heightWeight'] || 0).to_f
                weighted_children << { child: child, weight: weight }
              end
              
              if orientation == 'horizontal'
                alignment = get_hstack_alignment
                add_line "WeightedHStack(alignment: #{alignment}, spacing: 0, children: ["
              elsif orientation == 'vertical'
                alignment = get_vstack_alignment
                add_line "WeightedVStack(alignment: #{alignment}, spacing: 0, children: ["
              end
            elsif orientation == 'horizontal'
              # HStackでgravityを反映
              alignment = get_hstack_alignment
              add_line "HStack(alignment: #{alignment}, spacing: 0) {"
            elsif orientation == 'vertical' 
              # VStackでgravityを反映
              alignment = get_vstack_alignment
              add_line "VStack(alignment: #{alignment}, spacing: 0) {"
            else
              # orientationがない場合はZStack（重ね合わせ）
              # 相対配置が必要な場合は特別な処理
              if @needs_relative_positioning
                generate_relative_positioning_zstack(children)
                # 相対配置の場合はここで処理完了
              else
                # 通常のZStack
                alignment = get_zstack_alignment
                add_line "ZStack(alignment: #{alignment}) {"
              end
            end
            
            # 相対配置の場合は子要素の処理をスキップ
            if !@needs_relative_positioning || orientation
              if has_weights && (orientation == 'horizontal' || orientation == 'vertical')
                # WeightedStackの場合は特別な処理
                indent do
                  children.each_with_index do |child, index|
                    weight = (child['weight'] || child['widthWeight'] || child['heightWeight'] || 0).to_f
                    
                    # 各子要素を(view: AnyView, weight: CGFloat)のタプルとして追加
                    add_line "("
                    add_line "  view: AnyView("
                    
                    # 子要素を生成（visibilityは子要素で処理される）
                    indent do
                      # Pass parent orientation to child for proper frame handling
                      child['parent_orientation'] = orientation
                      child_converter = @converter_factory.create_converter(child, @indent_level + 1, @action_manager, @converter_factory, @view_registry)
                      child_code = child_converter.convert
                      child_lines = child_code.split("\n")
                      child_lines.each { |line| add_line line.strip }
                      
                      # State変数を継承
                      if child_converter.respond_to?(:state_variables) && child_converter.state_variables
                        @state_variables.concat(child_converter.state_variables)
                      end
                    end
                    
                    add_line "  ),"
                    add_line "  weight: #{weight}"
                    add_line ")#{index < children.size - 1 ? ',' : ''}"
                  end
                end
                add_line "])"  # WeightedStackの配列を閉じる
              else
                # 通常のStack処理
                indent do
                  children.each_with_index do |child, index|
                    if @converter_factory
                      render_child_element(child, orientation, index, 0, 0)
                    end
                  end
                end
              end
              
              # 閉じ括弧を追加
              # orientationがある場合（HStack/VStack）は常に閉じ括弧が必要
              # orientationがない場合（ZStack）は相対配置でない場合のみ
              if orientation || !@needs_relative_positioning
                if !has_weights || (orientation != 'horizontal' && orientation != 'vertical')
                  # 通常のStackの場合のみ閉じ括弧が必要
                  # WeightedStackは既に閉じている
                  add_line "}"  # 通常のStack/ZStackを閉じる
                end
              end
            end
            
            # ZStackで相対配置が必要な場合はcoordinateSpaceを設定
            if !orientation && has_relative_positioning?(children) && !@needs_relative_positioning
              add_modifier_line ".coordinateSpace(name: \"ZStackCoordinateSpace\")"
            end
          end
          
          # 共通のモディファイアを適用
          apply_modifiers
          
          # グラデーション
          if @component['gradient']
            apply_gradient
          end
          
          # SafeAreaViewの場合
          if @component['type'] == 'SafeAreaView' && @component['safeAreaInsetPositions']
            apply_safe_area_insets
          end
          
          generated_code
        end
      end
    end
  end
end