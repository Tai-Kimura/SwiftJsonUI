#!/usr/bin/env ruby

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class GradientViewConverter < BaseViewConverter
        def initialize(component, indent_level = 0, action_manager = nil, converter_factory = nil, view_registry = nil)
          super(component, indent_level, action_manager)
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
          if @component['gradient']
            apply_gradient_background
          end
          
          # 共通のモディファイアを適用
          apply_modifiers
          
          generated_code
        end
        
        private
        
        def apply_gradient_background
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
      end
    end
  end
end