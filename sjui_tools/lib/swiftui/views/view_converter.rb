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
        
        def should_add_leading_spacer_for_hstack(gravity)
          # HStack with right/trailing gravity needs leading spacer
          # Extract horizontal component from gravity
          horizontal = extract_horizontal_from_gravity(gravity)
          horizontal == 'right'
        end
        
        def get_alignment_for_single_child(child)
          # 子要素のアライメントプロパティからSwiftUIのAlignmentを決定
          return nil unless child.is_a?(Hash)
          
          horizontal = nil
          vertical = nil
          
          # 水平方向のアライメント
          if child['alignLeft']
            horizontal = 'leading'
          elsif child['alignRight']
            horizontal = 'trailing'
          elsif child['centerHorizontal'] || child['centerInParent']
            horizontal = 'center'
          end
          
          # 垂直方向のアライメント
          if child['alignTop']
            vertical = 'top'
          elsif child['alignBottom']
            vertical = 'bottom'
          elsif child['centerVertical'] || child['centerInParent']
            vertical = 'center'
          end
          
          # アライメントが指定されていない場合はnilを返す
          return nil unless horizontal || vertical
          
          # デフォルト値の設定（左上がデフォルト）
          horizontal ||= 'leading'
          vertical ||= 'top'
          
          # SwiftUIのAlignmentに変換
          case "#{vertical}_#{horizontal}"
          when 'top_leading'
            '.topLeading'
          when 'top_center'
            '.top'
          when 'top_trailing'
            '.topTrailing'
          when 'center_leading'
            '.leading'
          when 'center_center'
            '.center'
          when 'center_trailing'
            '.trailing'
          when 'bottom_leading'
            '.bottomLeading'
          when 'bottom_center'
            '.bottom'
          when 'bottom_trailing'
            '.bottomTrailing'
          else
            '.center'
          end
        end
        
        def should_add_trailing_spacer_for_hstack(gravity)
          # HStack with left/leading gravity needs trailing spacer
          horizontal = extract_horizontal_from_gravity(gravity)
          horizontal == 'left'
        end
        
        def should_add_leading_spacer_for_vstack(gravity)
          # VStack with bottom gravity needs leading spacer
          vertical = extract_vertical_from_gravity(gravity)
          vertical == 'bottom'
        end
        
        def should_add_trailing_spacer_for_vstack(gravity)
          # VStack with top gravity needs trailing spacer
          vertical = extract_vertical_from_gravity(gravity)
          vertical == 'top'
        end
        
        def extract_horizontal_from_gravity(gravity)
          gravity = gravity || 'left|top'
          if gravity.is_a?(Array)
            gravity.find { |g| ['left', 'center', 'right'].include?(g) } || 'left'
          elsif gravity.is_a?(String)
            if gravity.include?('|')
              parts = gravity.split('|')
              parts.find { |p| ['left', 'center', 'right'].include?(p) } || 'left'
            else
              ['left', 'center', 'right'].include?(gravity) ? gravity : 'left'
            end
          else
            'left'
          end
        end
        
        def extract_vertical_from_gravity(gravity)
          gravity = gravity || 'left|top'
          if gravity.is_a?(Array)
            gravity.find { |g| ['top', 'center', 'bottom'].include?(g) } || 'top'
          elsif gravity.is_a?(String)
            if gravity.include?('|')
              parts = gravity.split('|')
              parts.find { |p| ['top', 'center', 'bottom'].include?(p) } || 'top'
            else
              ['top', 'center', 'bottom'].include?(gravity) ? gravity : 'top'
            end
          else
            'top'
          end
        end
        
        def convert
          # ビューレジストリに自身を登録
          if @component['id'] && @view_registry
            @view_registry.register_view(@component['id'], @component)
          end
          
          child_data = @component['child'] || []
          # childが単一要素の場合は配列に変換
          children = child_data.is_a?(Array) ? child_data : [child_data]
          # Filter out data declarations - only if it's a data declaration (has 'data' key and no other view properties)
          children = children.reject { |child| 
            child.is_a?(Hash) && child['data'] && !child['type'] && !child['include']
          }
          
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
          elsif children.length == 1 && !@component['orientation']
            # 子要素が1つで、orientationが指定されていない場合
            # 子要素のアライメントプロパティをチェック
            child = children.first
            alignment = get_alignment_for_single_child(child)
            
            if alignment
              # アライメントが指定されている場合
              # render_child_elementは既にGroupを作成するので、それを利用
              if @converter_factory
                render_child_element(child, nil, 0, 0, 0)
              end
              # frameとalignmentを適用
              add_modifier_line ".frame(maxWidth: .infinity, maxHeight: .infinity, alignment: #{alignment})"
            else
              # アライメントがない場合は直接レンダリング
              if @converter_factory
                render_child_element(child, nil, 0, 0, 0)
              end
            end
          else
            # 複数の子要素がある場合、またはorientationが指定されている場合
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
              
              # Add Spacer at beginning for right gravity
              if should_add_leading_spacer_for_hstack(@component['gravity'])
                indent do
                  add_line "Spacer(minLength: 0)"
                end
              end
            elsif orientation == 'vertical' 
              # VStackでgravityを反映
              alignment = get_vstack_alignment
              add_line "VStack(alignment: #{alignment}, spacing: 0) {"
              
              # Add Spacer at beginning for bottom gravity
              if should_add_leading_spacer_for_vstack(@component['gravity'])
                indent do
                  add_line "Spacer(minLength: 0)"
                end
              end
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
                  
                  # Add trailing Spacer based on gravity
                  if orientation == 'horizontal' && should_add_trailing_spacer_for_hstack(@component['gravity'])
                    add_line "Spacer(minLength: 0)"
                  elsif orientation == 'vertical' && should_add_trailing_spacer_for_vstack(@component['gravity'])
                    add_line "Spacer(minLength: 0)"
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
          # 相対配置の場合、paddingはRelativePositionContainer内部で処理されるのでスキップ
          apply_modifiers(skip_padding: @needs_relative_positioning)
          
          # グラデーション
          if @component['gradient']
            apply_gradient
          end
          
          # SafeAreaViewの場合
          if @component['type'] == 'SafeAreaView' && @component['safeAreaInsetPositions']
            apply_safe_area_insets
          end
          
          # canTapの処理
          if @component['canTap'] == true || @component['canTap'] == 'true'
            add_modifier_line ".contentShape(Rectangle())"
            add_modifier_line ".onTapGesture {"
            indent do
              if @component['onclick'] || @component['onClick']
                action_name = @component['onclick'] || @component['onClick']
                if @action_manager
                  handler_name = @action_manager.register_action(action_name, 'tap')
                  add_line "#{handler_name}()"
                else
                  add_line "// Action: #{action_name}"
                end
              else
                add_line "// No action defined"
              end
            end
            add_line "}"
          end
          
          generated_code
        end
      end
    end
  end
end