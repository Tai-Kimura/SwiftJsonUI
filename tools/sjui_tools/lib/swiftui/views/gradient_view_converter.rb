#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class GradientViewConverter < BaseViewConverter
        def initialize(component, indent_level = 0, action_manager = nil, converter_factory = nil, view_registry = nil, binding_registry = nil)
          super(component, indent_level, action_manager, binding_registry)
          @converter_factory = converter_factory
          @view_registry = view_registry
        end
        
        def convert
          children = @component['child'] || []
          
          # 子要素を生成
          if children.empty?
            add_line "Color.clear"
          elsif children.length == 1
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
            add_line "VStack(spacing: 0) {"
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
          
          # グラデーション背景を適用
          if @component['colors'] || @component['gradient']
            apply_gradient_background
          end
          
          # 共通のモディファイアを適用
          apply_modifiers
          
          generated_code
        end
        
        private
        
        def apply_gradient_background
          # Handle colors property
          color_array = @component['colors'] || @component['gradient'] || []
          colors = color_array.map { |color| hex_to_swiftui_color(color) }
          
          # Handle start and end points
          if @component['startPoint'] && @component['endPoint']
            start_point = gradient_point(@component['startPoint'])
            end_point = gradient_point(@component['endPoint'])
            gradient_params = "startPoint: #{start_point}, endPoint: #{end_point}"
          else
            direction = @component['gradientDirection'] || 'Vertical'
            gradient_params = case direction
            when 'Horizontal'
              "startPoint: .leading, endPoint: .trailing"
            when 'Oblique'
              "startPoint: .topLeading, endPoint: .bottomTrailing"
            else
              "startPoint: .top, endPoint: .bottom"
            end
          end
          
          add_modifier_line ".background(LinearGradient(colors: [#{colors.join(', ')}], #{gradient_params}))"
        end
        
        def gradient_point(point)
          x = point['x'] || 0
          y = point['y'] || 0
          
          # Map common gradient points
          if x == 0 && y == 0
            ".topLeading"
          elsif x == 0.5 && y == 0
            ".top"
          elsif x == 1 && y == 0
            ".topTrailing"
          elsif x == 0 && y == 0.5
            ".leading"
          elsif x == 0.5 && y == 0.5
            ".center"
          elsif x == 1 && y == 0.5
            ".trailing"
          elsif x == 0 && y == 1
            ".bottomLeading"
          elsif x == 0.5 && y == 1
            ".bottom"
          elsif x == 1 && y == 1
            ".bottomTrailing"
          else
            "UnitPoint(x: #{x}, y: #{y})"
          end
        end
      end
    end
  end
end