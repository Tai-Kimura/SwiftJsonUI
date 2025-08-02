#!/usr/bin/env ruby

require_relative 'base_view_converter'

class ViewConverter < BaseViewConverter
  def initialize(component, indent_level = 0, converter_factory = nil)
    super(component, indent_level)
    @converter_factory = converter_factory
  end

  def convert
    children = @component['child'] || []
    orientation = @component['orientation'] || 'vertical'
    
    if children.empty?
      # 子要素がない場合は空のビュー
      add_line "EmptyView()"
    elsif children.length == 1
      # 子要素が1つの場合は直接生成
      if @converter_factory
        child_converter = @converter_factory.create_converter(children.first, @indent_level)
        @generated_code = child_converter.convert.split("\n")
      end
    else
      # 複数の子要素がある場合はStackを使用
      if orientation == 'horizontal'
        add_line "HStack(spacing: 0) {"
      else
        add_line "VStack(spacing: 0) {"
      end
      
      indent do
        children.each do |child|
          if @converter_factory
            # weightプロパティの処理
            has_weight = child['weight'] && child['weight'].to_f > 0
            
            child_converter = @converter_factory.create_converter(child, @indent_level)
            child_code = child_converter.convert
            child_lines = child_code.split("\n")
            
            child_lines.each { |line| @generated_code << line }
            
            # weightがある場合、frameを追加
            if has_weight && orientation == 'horizontal'
              add_modifier_line ".frame(maxWidth: .infinity)"
            elsif has_weight && orientation == 'vertical'
              add_modifier_line ".frame(maxHeight: .infinity)"
            end
          end
        end
      end
      add_line "}"
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