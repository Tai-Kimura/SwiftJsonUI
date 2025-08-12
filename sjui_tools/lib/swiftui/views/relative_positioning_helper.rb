#!/usr/bin/env ruby

module SjuiTools
  module SwiftUI
    module Views
      # Helper module for relative positioning logic
      module RelativePositioningHelper
        def has_relative_constraint?(child)
          return false unless child.is_a?(Hash)
          
          # 相対配置のプロパティをチェック
          child['toLeftOf'] || child['toRightOf'] || child['above'] || child['below'] ||
          child['alignTop'] || child['alignBottom'] || child['alignLeft'] || child['alignRight'] ||
          child['alignBaseline'] || child['centerHorizontal'] || child['centerVertical'] ||
          child['centerInParent'] || child['toStartOf'] || child['toEndOf']
        end
        
        def has_relative_positioning?(children)
          return false unless children.is_a?(Array)
          
          children.any? do |child|
            next false unless child.is_a?(Hash)
            has_relative_constraint?(child)
          end
        end
        
        def calculate_relative_positions(children)
          # 相対配置の計算を行う
          positions = {}
          children.each_with_index do |child, index|
            next unless child.is_a?(Hash)
            
            # 各子要素のIDまたはインデックスをキーとして使用
            child_id = child['id'] || "child_#{index}"
            
            # 相対配置の制約を解析
            constraints = []
            
            # 水平方向の制約
            if child['toLeftOf']
              constraints << { type: :toLeftOf, target: child['toLeftOf'] }
            elsif child['toRightOf']
              constraints << { type: :toRightOf, target: child['toRightOf'] }
            elsif child['toStartOf']
              constraints << { type: :toStartOf, target: child['toStartOf'] }
            elsif child['toEndOf']
              constraints << { type: :toEndOf, target: child['toEndOf'] }
            end
            
            # 垂直方向の制約
            if child['above']
              constraints << { type: :above, target: child['above'] }
            elsif child['below']
              constraints << { type: :below, target: child['below'] }
            end
            
            # アライメント制約
            if child['alignLeft']
              if child['alignLeft'].is_a?(String)
                constraints << { type: :alignLeft, target: child['alignLeft'] }
              else
                constraints << { type: :alignLeft, target: :parent }
              end
            end
            
            if child['alignRight']
              if child['alignRight'].is_a?(String)
                constraints << { type: :alignRight, target: child['alignRight'] }
              else
                constraints << { type: :alignRight, target: :parent }
              end
            end
            
            if child['alignTop']
              if child['alignTop'].is_a?(String)
                constraints << { type: :alignTop, target: child['alignTop'] }
              else
                constraints << { type: :alignTop, target: :parent }
              end
            end
            
            if child['alignBottom']
              if child['alignBottom'].is_a?(String)
                constraints << { type: :alignBottom, target: child['alignBottom'] }
              else
                constraints << { type: :alignBottom, target: :parent }
              end
            end
            
            if child['centerHorizontal']
              if child['centerHorizontal'].is_a?(String)
                constraints << { type: :centerHorizontal, target: child['centerHorizontal'] }
              else
                constraints << { type: :centerHorizontal, target: :parent }
              end
            end
            
            if child['centerVertical']
              if child['centerVertical'].is_a?(String)
                constraints << { type: :centerVertical, target: child['centerVertical'] }
              else
                constraints << { type: :centerVertical, target: :parent }
              end
            end
            
            if child['centerInParent']
              constraints << { type: :centerInParent, target: :parent }
            end
            
            positions[child_id] = {
              constraints: constraints,
              margins: {
                top: child['topMargin'] || child['marginTop'] || 0,
                bottom: child['bottomMargin'] || child['marginBottom'] || 0,
                left: child['leftMargin'] || child['marginLeft'] || child['startMargin'] || child['marginStart'] || 0,
                right: child['rightMargin'] || child['marginRight'] || child['endMargin'] || child['marginEnd'] || 0
              }
            }
          end
          
          positions
        end
        
        def generate_relative_positioning_zstack(children)
          # RelativePositionContainerを使用した実装
          # 親のみの制約を持つ子要素がある場合、その要素のアライメントから決定
          parent_only_children = children.select do |child|
            next false unless child.is_a?(Hash)
            # 親への制約のみ持つかチェック（他のビューへの制約がない）
            has_parent = child['alignTop'] || child['alignBottom'] || child['alignLeft'] || child['alignRight'] ||
                        child['centerHorizontal'] || child['centerVertical'] || child['centerInParent']
            has_relative = child['toLeftOf'] || child['toRightOf'] || child['above'] || child['below'] ||
                          child['toStartOf'] || child['toEndOf']
            has_parent && !has_relative
          end
          
          if parent_only_children.any?
            # 親のみの制約を持つ最初の要素のアライメントを使用
            alignment = get_zstack_alignment_for_child(parent_only_children.first) || '.center'
          else
            alignment = get_zstack_alignment
          end
          
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
                    child_id = child['id'] || "view_#{index}"
                    add_line "id: \"#{child_id}\","
                    
                    # View
                    add_line "view: AnyView("
                    indent do
                      child_converter = @converter_factory.create_converter(child, @indent_level + 2, @action_manager, @converter_factory, @view_registry)
                      child_code = child_converter.convert
                      child_lines = child_code.split("\n")
                      child_lines.each do |line|
                        add_line line.strip unless line.strip.empty?
                      end
                    end
                    add_line "),"
                    
                    # Constraints
                    add_line "constraints: ["
                    indent do
                      # 相対配置の制約を追加
                      constraint_added = false
                      
                      # toLeftOf/toRightOf
                      if child['toLeftOf']
                        add_line "RelativePositionConstraint(type: .toLeftOf, targetId: \"#{child['toLeftOf']}\"),"
                        constraint_added = true
                      elsif child['toRightOf']
                        add_line "RelativePositionConstraint(type: .toRightOf, targetId: \"#{child['toRightOf']}\"),"
                        constraint_added = true
                      elsif child['toStartOf']
                        add_line "RelativePositionConstraint(type: .toStartOf, targetId: \"#{child['toStartOf']}\"),"
                        constraint_added = true
                      elsif child['toEndOf']
                        add_line "RelativePositionConstraint(type: .toEndOf, targetId: \"#{child['toEndOf']}\"),"
                        constraint_added = true
                      end
                      
                      # above/below
                      if child['above']
                        add_line "RelativePositionConstraint(type: .above, targetId: \"#{child['above']}\"),"
                        constraint_added = true
                      elsif child['below']
                        add_line "RelativePositionConstraint(type: .below, targetId: \"#{child['below']}\"),"
                        constraint_added = true
                      end
                      
                      # アライメント制約（水平方向を先に）
                      if child['alignLeft']
                        target = child['alignLeft'].is_a?(String) ? "\"#{child['alignLeft']}\"" : "\"\""
                        add_line "RelativePositionConstraint(type: .#{child['alignLeft'].is_a?(String) ? 'left' : 'parentLeft'}, targetId: #{target}),"
                        constraint_added = true
                      end
                      
                      if child['alignRight']
                        target = child['alignRight'].is_a?(String) ? "\"#{child['alignRight']}\"" : "\"\""
                        add_line "RelativePositionConstraint(type: .#{child['alignRight'].is_a?(String) ? 'right' : 'parentRight'}, targetId: #{target}),"
                        constraint_added = true
                      end
                      
                      if child['alignTop']
                        target = child['alignTop'].is_a?(String) ? "\"#{child['alignTop']}\"" : "\"\""
                        add_line "RelativePositionConstraint(type: .#{child['alignTop'].is_a?(String) ? 'top' : 'parentTop'}, targetId: #{target}),"
                        constraint_added = true
                      end
                      
                      if child['alignBottom']
                        target = child['alignBottom'].is_a?(String) ? "\"#{child['alignBottom']}\"" : "\"\""
                        add_line "RelativePositionConstraint(type: .#{child['alignBottom'].is_a?(String) ? 'bottom' : 'parentBottom'}, targetId: #{target}),"
                        constraint_added = true
                      end
                      
                      if child['centerHorizontal']
                        target = child['centerHorizontal'].is_a?(String) ? "\"#{child['centerHorizontal']}\"" : "\"\""
                        add_line "RelativePositionConstraint(type: .#{child['centerHorizontal'].is_a?(String) ? 'centerHorizontal' : 'parentCenterHorizontal'}, targetId: #{target}),"
                        constraint_added = true
                      end
                      
                      if child['centerVertical']
                        target = child['centerVertical'].is_a?(String) ? "\"#{child['centerVertical']}\"" : "\"\""
                        add_line "RelativePositionConstraint(type: .#{child['centerVertical'].is_a?(String) ? 'centerVertical' : 'parentCenterVertical'}, targetId: #{target}),"
                        constraint_added = true
                      end
                      
                      if child['centerInParent']
                        add_line "RelativePositionConstraint(type: .parentCenter, targetId: \"\"),"
                        constraint_added = true
                      end
                      
                      # 最後のカンマを削除
                      if constraint_added && @generated_code.last.end_with?(',')
                        @generated_code[-1] = @generated_code.last.chomp(',')
                      end
                    end
                    add_line "],"
                    
                    # Margins
                    margins = []
                    margins << "top: #{child['topMargin'] || child['marginTop'] || 0}"
                    margins << "leading: #{child['leftMargin'] || child['marginLeft'] || child['startMargin'] || child['marginStart'] || 0}"
                    margins << "bottom: #{child['bottomMargin'] || child['marginBottom'] || 0}"
                    margins << "trailing: #{child['rightMargin'] || child['marginRight'] || child['endMargin'] || child['marginEnd'] || 0}"
                    
                    # デフォルト値でない場合のみマージンを設定
                    if margins.any? { |m| !m.end_with?(' 0') }
                      add_line "margins: EdgeInsets(#{margins.join(', ')})"
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
            
            # 背景色
            if @component['background']
              bg_color = hex_to_swiftui_color(@component['background'])
              add_line "backgroundColor: #{bg_color}"
            else
              add_line "backgroundColor: nil"
            end
          end
          add_line ")"
        end
      end
    end
  end
end