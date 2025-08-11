#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class ViewConverter < BaseViewConverter
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
          elsif children.length == 1
            # 子要素が1つの場合でも、alignmentが必要な場合はZStackを使用
            child = children.first
            needs_alignment = child['centerInParent'] || child['centerVertical'] || child['centerHorizontal'] ||
                            child['alignTop'] || child['alignBottom'] || child['alignLeft'] || child['alignRight']
            
            if needs_alignment && !@component['orientation']
              # orientationがなく、alignmentが必要な場合はZStack
              alignment = get_zstack_alignment_for_child(child)
              add_line "ZStack(alignment: #{alignment}) {"
              
              indent do
                # ZStackのサイズを確保するために透明なColorを追加
                add_line "Color.clear"
                
                if @converter_factory
                  child_converter = @converter_factory.create_converter(child, @indent_level, @action_manager)
                  child_code = child_converter.convert
                  child_lines = child_code.split("\n")
                  child_lines.each { |line| @generated_code << line }
                  
                  # Propagate state variables
                  if child_converter.respond_to?(:state_variables) && child_converter.state_variables
                    @state_variables.concat(child_converter.state_variables)
                  end
                end
              end
              
              add_line "}"
            else
              # alignmentが不要またはorientationがある場合は直接生成
              if @converter_factory
                child_converter = @converter_factory.create_converter(children.first, @indent_level, @action_manager)
                child_code = child_converter.convert
                @generated_code = child_code.split("\n")
                
                # Propagate state variables
                if child_converter.respond_to?(:state_variables) && child_converter.state_variables
                  @state_variables.concat(child_converter.state_variables)
                end
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
              # 重みの合計と各子要素の重みを計算
              total_weight = 0.0
              weights = []
              children.each do |child|
                weight = (child['weight'] || child['widthWeight'] || child['heightWeight'] || 0).to_f
                weights << weight
                total_weight += weight if weight > 0
              end
              
              # 重みがある子要素の存在をチェック
              has_weights = total_weight > 0
              
              # GeometryReaderを使って重み配分を実装（必要な場合）
              if has_weights && (orientation == 'horizontal' || orientation == 'vertical')
                add_line "GeometryReader { geometry in"
                indent do
                  # スタックを開始
                  if orientation == 'horizontal'
                    alignment = get_hstack_alignment
                    add_line "HStack(alignment: #{alignment}, spacing: 0) {"
                  elsif orientation == 'vertical'
                    alignment = get_vstack_alignment
                    add_line "VStack(alignment: #{alignment}, spacing: 0) {"
                  end
                  
                  indent do
                    children.each_with_index do |child, index|
                      weight = weights[index]
                      
                      if @converter_factory
                        child_converter = @converter_factory.create_converter(child, @indent_level, @action_manager, @converter_factory, @view_registry)
                        child_code = child_converter.convert
                        child_lines = child_code.split("\n")
                        child_lines.each { |line| @generated_code << line }
                        
                        # Propagate state variables
                        if child_converter.respond_to?(:state_variables) && child_converter.state_variables
                          @state_variables.concat(child_converter.state_variables)
                        end
                        
                        # 重みに基づいてframeを設定
                        if weight > 0
                          if orientation == 'horizontal'
                            width_ratio = weight / total_weight
                            add_modifier_line ".frame(width: geometry.size.width * #{width_ratio.round(4)})"
                          elsif orientation == 'vertical'
                            height_ratio = weight / total_weight
                            add_modifier_line ".frame(height: geometry.size.height * #{height_ratio.round(4)})"
                          end
                        end
                      end
                    end
                  end
                  
                  add_line "}"
                end
                add_line "}"
              else
                # 重みがない場合は通常の処理
                indent do
                  children.each_with_index do |child, index|
                    if @converter_factory
                      # ZStackの場合、位置関係の処理
                      if !orientation
                        # 通常のZStackでの子要素をグループ化
                        add_line "Group {"
                      end
                    
                    # Wrap with VisibilityWrapper if visibility is set
                    if child['visibility']
                      visibility_value = child['visibility']
                      # Check if it's a binding
                      if visibility_value.is_a?(String) && visibility_value.start_with?('@{') && visibility_value.end_with?('}')
                        var_name = to_camel_case(visibility_value[2..-2])
                        visibility_param = var_name
                      else
                        visibility_param = "\"#{visibility_value}\""
                      end
                      
                      # Create child converter with extra indent level for content inside VisibilityWrapper
                      child_converter = @converter_factory.create_converter(child, @indent_level + 1, @action_manager, @converter_factory, @view_registry)
                      child_code = child_converter.convert
                      
                      # Add VisibilityWrapper wrapper
                      add_line "VisibilityWrapper(#{visibility_param}) {"
                      indent do
                        child_code.split("\n").each { |line| @generated_code << line }
                      end
                      add_line "}"
                    else
                      # Normal child without visibility wrapper
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
                    end
                    
                    # Propagate state variables
                    if child_converter.respond_to?(:state_variables) && child_converter.state_variables
                      @state_variables.concat(child_converter.state_variables)
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
              end
              
              # 相対配置でない場合のみ閉じ括弧を追加
              if !@needs_relative_positioning
                add_line "}"
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
        
        private
        
        def generate_relative_positioning_zstack(children)
          # RelativePositionContainerを使用した実装
          alignment = get_zstack_alignment
          
          add_line "RelativePositionContainer("
          indent do
            add_line "children: ["
            indent do
              children.each_with_index do |child, index|
                if @converter_factory
                  # 子ビューの設定を生成
                  add_line "RelativeChildConfig("
                  indent do
                    # ID
                    if child['id']
                      add_line "id: \"#{child['id']}\","
                    else
                      add_line "id: \"view_#{index}\","
                    end
                    
                    # View
                    add_line "view: AnyView("
                    indent do
                      # Create a copy to avoid modifying the original
                      child_copy = child.dup
                      # Remove properties that are handled by RelativePositionContainer
                      child_copy.delete('alignTopOfView')
                      child_copy.delete('alignBottomOfView')
                      child_copy.delete('alignLeftOfView')
                      child_copy.delete('alignRightOfView')
                      child_copy.delete('alignTopView')
                      child_copy.delete('alignBottomView')
                      child_copy.delete('alignLeftView')
                      child_copy.delete('alignRightView')
                      # Keep margins since they may be used for additional offset
                      # But don't delete centerInParent, centerHorizontal, centerVertical as they might affect internal layout
                      
                      child_converter = @converter_factory.create_converter(child_copy, @indent_level, @action_manager, @converter_factory, @view_registry)
                      child_code = child_converter.convert
                      child_lines = child_code.split("\n")
                      child_lines.each { |line| @generated_code << line }
                      
                      # Propagate state variables
                      if child_converter.respond_to?(:state_variables) && child_converter.state_variables
                        @state_variables.concat(child_converter.state_variables)
                      end
                    end
                    add_line "),"
                    
                    # Constraints
                    constraints = []
                    
                    # Check for centerInParent first - this should position the view in the center
                    if child['centerInParent']
                      # For center positioning, we don't need constraints, just use the alignment
                      # The container's alignment will handle this
                    end
                    
                    # alignTopOfView, alignBottomOfView, etc. (position outside the view)
                    if child['alignTopOfView']
                      constraints << "RelativePositionConstraint(type: .above, targetId: \"#{child['alignTopOfView']}\")"
                    end
                    if child['alignBottomOfView']
                      constraints << "RelativePositionConstraint(type: .below, targetId: \"#{child['alignBottomOfView']}\")"
                    end
                    if child['alignLeftOfView']
                      constraints << "RelativePositionConstraint(type: .leftOf, targetId: \"#{child['alignLeftOfView']}\")"
                    end
                    if child['alignRightOfView']
                      constraints << "RelativePositionConstraint(type: .rightOf, targetId: \"#{child['alignRightOfView']}\")"
                    end
                    
                    # alignTopView, alignBottomView, etc. (align edges)
                    if child['alignTopView']
                      spacing = child['topMargin'] || 0
                      constraints << "RelativePositionConstraint(type: .alignTop, targetId: \"#{child['alignTopView']}\", spacing: #{spacing})"
                    end
                    if child['alignBottomView']
                      spacing = child['topMargin'] || 0
                      constraints << "RelativePositionConstraint(type: .alignBottom, targetId: \"#{child['alignBottomView']}\", spacing: #{spacing})"
                    end
                    if child['alignLeftView']
                      spacing = child['leftMargin'] || 0
                      constraints << "RelativePositionConstraint(type: .alignLeft, targetId: \"#{child['alignLeftView']}\", spacing: #{spacing})"
                    end
                    if child['alignRightView']
                      spacing = child['leftMargin'] || 0
                      constraints << "RelativePositionConstraint(type: .alignRight, targetId: \"#{child['alignRightView']}\", spacing: #{spacing})"
                    end
                    
                    if constraints.any?
                      add_line "constraints: ["
                      indent do
                        constraints.each do |constraint|
                          add_line "#{constraint},"
                        end
                      end
                      add_line "],"
                    else
                      add_line "constraints: [],"
                    end
                    
                    # Margins
                    top_margin = child['topMargin'] || 0
                    bottom_margin = child['bottomMargin'] || 0
                    left_margin = child['leftMargin'] || 0
                    right_margin = child['rightMargin'] || 0
                    
                    if top_margin > 0 || bottom_margin > 0 || left_margin > 0 || right_margin > 0
                      add_line "margins: EdgeInsets(top: #{top_margin}, leading: #{left_margin}, bottom: #{bottom_margin}, trailing: #{right_margin})"
                    else
                      add_line "margins: .init()"
                    end
                  end
                  add_line index < children.length - 1 ? ")," : ")"
                end
              end
            end
            add_line "],"
            add_line "alignment: #{alignment},"
            if @component['background']
              add_line "backgroundColor: #{hex_to_swiftui_color(@component['background'])}"
            else
              add_line "backgroundColor: nil"
            end
          end
          add_line ")"
        end
        
        def has_relative_constraint?(child)
          child['alignTopOfView'] || child['alignBottomOfView'] || 
          child['alignLeftOfView'] || child['alignRightOfView'] ||
          child['alignTopView'] || child['alignBottomView'] ||
          child['alignLeftView'] || child['alignRightView']
        end
        
        def calculate_relative_positions(children)
          positions = {}
          view_bounds = {}
          
          # まず、各ビューの仮想的な位置とサイズを計算
          children.each_with_index do |child, index|
            next unless child.is_a?(Hash)
            
            # デフォルトの位置とサイズ
            x = child['leftMargin'] || 0
            y = child['topMargin'] || 0
            width = child['width'] || 100
            height = child['height'] || 100
            
            if child['id']
              view_bounds[child['id']] = {
                x: x,
                y: y,
                width: width,
                height: height
              }
            end
            
            positions[index] = { x: x, y: y }
          end
          
          # 相対配置の計算
          children.each_with_index do |child, index|
            next unless child.is_a?(Hash)
            
            offset_x = positions[index][:x]
            offset_y = positions[index][:y]
            
            # alignRightOfView: 指定ビューの右端に配置
            if child['alignRightOfView'] && view_bounds[child['alignRightOfView']]
              target = view_bounds[child['alignRightOfView']]
              offset_x = target[:x] + target[:width] + (child['leftMargin'] || 0)
            end
            
            # alignLeftOfView: 指定ビューの左端に配置
            if child['alignLeftOfView'] && view_bounds[child['alignLeftOfView']]
              target = view_bounds[child['alignLeftOfView']]
              offset_x = target[:x] - (child['width'] || 100) - (child['rightMargin'] || 0)
            end
            
            # alignTopOfView: 指定ビューの上端に揃える
            if child['alignTopOfView'] && view_bounds[child['alignTopOfView']]
              target = view_bounds[child['alignTopOfView']]
              offset_y = target[:y]
            end
            
            # alignBottomOfView: 指定ビューの下端に揃える
            if child['alignBottomOfView'] && view_bounds[child['alignBottomOfView']]
              target = view_bounds[child['alignBottomOfView']]
              offset_y = target[:y] + target[:height] - (child['height'] || 100)
            end
            
            # alignBottomView: 指定ビューの下に配置
            if child['alignBottomView'] && view_bounds[child['alignBottomView']]
              target = view_bounds[child['alignBottomView']]
              offset_y = target[:y] + target[:height] + (child['topMargin'] || 0)
            end
            
            # alignTopView: 指定ビューの上に配置
            if child['alignTopView'] && view_bounds[child['alignTopView']]
              target = view_bounds[child['alignTopView']]
              offset_y = target[:y] - (child['height'] || 100) - (child['bottomMargin'] || 0)
            end
            
            # alignRightView: 指定ビューの右に配置
            if child['alignRightView'] && view_bounds[child['alignRightView']]
              target = view_bounds[child['alignRightView']]
              offset_x = target[:x] + target[:width] + (child['leftMargin'] || 0)
            end
            
            # alignLeftView: 指定ビューの左に配置
            if child['alignLeftView'] && view_bounds[child['alignLeftView']]
              target = view_bounds[child['alignLeftView']]
              offset_x = target[:x] - (child['width'] || 100) - (child['rightMargin'] || 0)
            end
            
            positions[index] = { x: offset_x, y: offset_y }
            
            # 更新した位置をview_boundsにも反映
            if child['id']
              view_bounds[child['id']][:x] = offset_x
              view_bounds[child['id']][:y] = offset_y
            end
          end
          
          positions
        end
        
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
        
        def get_zstack_alignment_for_child(child)
          # 子要素のalignmentプロパティからZStackのalignmentを決定
          if child['centerInParent']
            return '.center'
          end
          
          h_align = nil
          v_align = nil
          
          # 水平方向のalignment
          if child['centerHorizontal']
            h_align = 'center'
          elsif child['alignRight']
            h_align = 'trailing'
          elsif child['alignLeft']
            h_align = 'leading'
          else
            # デフォルトは左
            h_align = 'leading'
          end
          
          # 垂直方向のalignment
          if child['centerVertical']
            v_align = 'center'
          elsif child['alignBottom']
            v_align = 'bottom'
          elsif child['alignTop']
            v_align = 'top'
          else
            # デフォルトは上
            v_align = 'top'
          end
          
          # 組み合わせてSwiftUIのAlignmentを返す
          case "#{v_align}|#{h_align}"
          when 'top|leading'
            '.topLeading'
          when 'top|center'
            '.top'
          when 'top|trailing'
            '.topTrailing'
          when 'center|leading'
            '.leading'
          when 'center|center'
            '.center'
          when 'center|trailing'
            '.trailing'
          when 'bottom|leading'
            '.bottomLeading'
          when 'bottom|center'
            '.bottom'
          when 'bottom|trailing'
            '.bottomTrailing'
          else
            '.topLeading'
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