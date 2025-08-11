#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class ViewConverter < BaseViewConverter
        def initialize(component, indent_level = 0, action_manager = nil, converter_factory = nil, view_registry = nil)
          super(component, indent_level, action_manager)
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
          elsif children.length == 1
            # 子要素が1つの場合は直接生成
            if @converter_factory
              child_converter = @converter_factory.create_converter(children.first, @indent_level, @action_manager)
              child_code = child_converter.convert
              @generated_code = child_code.split("\n")
              
              # Propagate state variables
              if child_converter.respond_to?(:state_variables) && child_converter.state_variables
                @state_variables.concat(child_converter.state_variables)
              end
            end
            
            # 単一の子要素でもモディファイアを適用する必要がある
            apply_modifiers
            return generated_code
          else
            # 複数の子要素がある場合
            # orientationが指定されていない場合はZStackを使用
            orientation = @component['orientation']
            
            if orientation == 'horizontal'
              # HStackでgravityを反映
              alignment = get_hstack_alignment
              add_line "HStack(alignment: #{alignment}, spacing: 0) {"
            elsif orientation == 'vertical' 
              # VStackでgravityを反映
              alignment = get_vstack_alignment
              add_line "VStack(alignment: #{alignment}, spacing: 0) {"
            else
              # orientationがない場合はZStack（重ね合わせ）
              # SwiftJsonUIのデフォルトは左上なので、.topLeadingを使用
              alignment = get_zstack_alignment
              add_line "ZStack(alignment: #{alignment}) {"
            end
            
            indent do
              children.each_with_index do |child, index|
                if @converter_factory
                  # ZStackの場合、位置関係の処理
                  if !orientation
                    # ZStackでの子要素をグループ化
                    add_line "Group {"
                  end
                  
                  # weightプロパティの処理（weightまたはwidthWeightをサポート）
                  weight_value = child['weight'] || child['widthWeight']
                  has_weight = weight_value && weight_value.to_f > 0
                  
                  child_converter = @converter_factory.create_converter(child, @indent_level, @action_manager, @converter_factory, @view_registry)
                  child_code = child_converter.convert
                  child_lines = child_code.split("\n")
                  
                  # Indent child code if inside Group (ZStack)
                  if !orientation
                    indent do
                      child_lines.each { |line| @generated_code << line }
                    end
                  else
                    child_lines.each { |line| @generated_code << line }
                  end
                  
                  # Propagate state variables
                  if child_converter.respond_to?(:state_variables) && child_converter.state_variables
                    @state_variables.concat(child_converter.state_variables)
                  end
                  
                  # weightがある場合、frameを追加
                  if has_weight && orientation == 'horizontal'
                    add_modifier_line ".frame(maxWidth: .infinity)"
                  elsif has_weight && orientation == 'vertical'
                    add_modifier_line ".frame(maxHeight: .infinity)"
                  end
                  
                  # ZStackの場合、位置調整を適用
                  if !orientation
                    indent do
                      apply_zstack_positioning(child, index)
                    end
                    add_line "}"  # Group終了
                  end
                end
              end
            end
            add_line "}"
            
            # ZStackで相対配置が必要な場合はcoordinateSpaceを設定
            if !orientation && has_relative_positioning?(children)
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
        
        private
        
        def has_relative_positioning?(children)
          children.any? do |child|
            child['alignTopOfView'] || child['alignBottomOfView'] || 
            child['alignLeftOfView'] || child['alignRightOfView'] ||
            child['alignTopView'] || child['alignBottomView'] ||
            child['alignLeftView'] || child['alignRightView']
          end
        end
        
        def get_hstack_alignment
          # HStackの垂直方向のアライメント
          # SwiftJsonUIのgravityから垂直成分を抽出
          # 例: "center|bottom" → "bottom", "bottom" → "bottom", ["center", "bottom"] → "bottom"
          gravity = @component['gravity'] || 'left|top'
          
          # gravityから垂直成分を取得
          vertical = 'top'  # デフォルト
          
          if gravity.is_a?(Array)
            # 配列の場合、垂直方向の値を探す
            vertical = gravity.find { |g| ['top', 'center', 'bottom'].include?(g) } || 'top'
          elsif gravity.is_a?(String)
            if gravity.include?('|')
              parts = gravity.split('|')
              vertical = parts.find { |p| ['top', 'center', 'bottom'].include?(p) } || 'top'
            else
              # 単一値でも垂直方向の値なら使用（例: "bottom"だけでもOK）
              vertical = ['top', 'center', 'bottom'].include?(gravity) ? gravity : 'top'
            end
          end
          
          case vertical
          when 'top'
            '.top'
          when 'center'
            '.center'
          when 'bottom'
            '.bottom'
          else
            '.top'  # デフォルトは上揃え
          end
        end
        
        def get_vstack_alignment
          # VStackの水平方向のアライメント
          # SwiftJsonUIのgravityから水平成分を抽出
          # 例: "right|center" → "right", "right" → "right", ["right", "center"] → "right"
          gravity = @component['gravity'] || 'left|top'
          
          # gravityから水平成分を取得
          horizontal = 'left'  # デフォルト
          
          if gravity.is_a?(Array)
            # 配列の場合、水平方向の値を探す
            horizontal = gravity.find { |g| ['left', 'center', 'right'].include?(g) } || 'left'
          elsif gravity.is_a?(String)
            if gravity.include?('|')
              parts = gravity.split('|')
              horizontal = parts.find { |p| ['left', 'center', 'right'].include?(p) } || 'left'
            else
              # 単一値でも水平方向の値なら使用（例: "right"だけでもOK）
              horizontal = ['left', 'center', 'right'].include?(gravity) ? gravity : 'left'
            end
          end
          
          case horizontal
          when 'left'
            '.leading'
          when 'center'
            '.center'
          when 'right'
            '.trailing'
          else
            '.leading'  # デフォルトは左揃え
          end
        end
        
        def get_zstack_alignment
          # ZStackのアライメントを決定
          # SwiftJsonUIのgravityプロパティから変換
          # SwiftJsonUIのデフォルトは左上
          gravity = @component['gravity'] || 'left|top'
          
          # gravityが配列の場合、水平と垂直の値を抽出
          if gravity.is_a?(Array)
            horizontal = gravity.find { |g| ['left', 'center', 'right'].include?(g) } || 'left'
            vertical = gravity.find { |g| ['top', 'center', 'bottom'].include?(g) } || 'top'
            gravity_str = "#{horizontal}|#{vertical}"
          else
            gravity_str = gravity.to_s
          end
          
          case gravity_str
          when 'left|top', 'top|left', 'left', 'top'
            '.topLeading'
          when 'center|top', 'top|center'
            '.top'
          when 'right|top', 'top|right'
            '.topTrailing'
          when 'left|center', 'center|left'
            '.leading'
          when 'center', 'center|center'
            '.center'
          when 'right|center', 'center|right', 'right'
            '.trailing'
          when 'left|bottom', 'bottom|left'
            '.bottomLeading'
          when 'center|bottom', 'bottom|center', 'bottom'
            '.bottom'
          when 'right|bottom', 'bottom|right'
            '.bottomTrailing'
          else
            '.topLeading'  # デフォルトは左上
          end
        end
        
        def apply_zstack_positioning(child, index)
          # 各子要素の位置を調整
          # SwiftJsonUIの各種margin属性を使用してoffsetを計算
          offset_x = 0
          offset_y = 0
          
          # 個別のmargin属性から位置を計算
          left_margin = child['leftMargin'] || 0
          right_margin = child['rightMargin'] || 0
          top_margin = child['topMargin'] || 0
          bottom_margin = child['bottomMargin'] || 0
          
          # 相対配置属性の処理（alignTopOfView, alignBottomOfView, alignLeftOfView, alignRightOfView）
          # または代替形式（alignTopView, alignBottomView, alignLeftView, alignRightView）
          has_relative_positioning = child['alignTopOfView'] || child['alignBottomOfView'] || 
                                    child['alignLeftOfView'] || child['alignRightOfView'] ||
                                    child['alignTopView'] || child['alignBottomView'] ||
                                    child['alignLeftView'] || child['alignRightView']
          
          if has_relative_positioning && @view_registry && child['id']
            # ViewRegistryから相対配置のモディファイアを取得
            modifiers = @view_registry.generate_alignment_modifiers(child['id'])
            modifiers.each do |modifier|
              add_modifier_line modifier
            end
          end
          
          # 通常のoffset計算（相対配置がない場合、または追加の調整として）
          if !has_relative_positioning
            # 通常のoffset計算
            # ZStackでは左上を基準にoffsetを計算
            offset_x = left_margin - right_margin
            offset_y = top_margin - bottom_margin
            
            # SwiftJsonUIの位置属性を処理
            # centerInParent
            if child['centerInParent']
              # ZStackのalignmentで処理されるため、追加のoffsetは不要
            end
            
            # centerVertical / centerHorizontal
            if child['centerVertical'] && !child['centerInParent']
              # 垂直方向のみセンタリング（offsetのy成分をリセット）
              offset_y = 0
            end
            
            if child['centerHorizontal'] && !child['centerInParent']
              # 水平方向のみセンタリング（offsetのx成分をリセット）
              offset_x = 0
            end
            
            # offsetを適用
            if offset_x != 0 || offset_y != 0
              add_modifier_line ".offset(x: #{offset_x}, y: #{offset_y})"
            end
          end
          
          # z-indexの処理（デフォルトは描画順序）
          add_modifier_line ".zIndex(#{index})"
        end
        
        def apply_gradient
          colors = @component['gradient'].map { |color| hex_to_swiftui_color(color) }
          direction = @component['gradientDirection'] || 'Vertical'
          
          gradient_type = case direction
          when 'Horizontal'
            "startPoint: .leading, endPoint: .trailing"
          when 'Oblique'
            "startPoint: .topLeading, endPoint: .bottomTrailing"
          else
            "startPoint: .top, endPoint: .bottom"
          end
          
          add_modifier_line ".background(LinearGradient(colors: [#{colors.join(', ')}], #{gradient_type}))"
        end
        
        def apply_safe_area_insets
          positions = @component['safeAreaInsetPositions']
          edges = []
          
          positions.each do |pos|
            case pos
            when 'top'
              edges << '.top'
            when 'bottom'
              edges << '.bottom'
            when 'left', 'leading'
              edges << '.leading'
            when 'right', 'trailing'
              edges << '.trailing'
            when 'vertical'
              edges += ['.top', '.bottom']
            when 'horizontal'
              edges += ['.leading', '.trailing']
            when 'all'
              edges = ['.all']
              break
            end
          end
          
          if edges.any?
            edge_set = edges.length == 1 ? edges.first : "[#{edges.uniq.join(', ')}]"
            add_modifier_line ".edgesIgnoringSafeArea(#{edge_set})"
          end
        end
      end
    end
  end
end