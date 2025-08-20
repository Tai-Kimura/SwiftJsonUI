# frozen_string_literal: true

module SjuiTools
  module SwiftUI
    module Helpers
      # Helper module for font-related conversions and processing
      module FontHelper
        # Apply font modifiers based on component attributes
        # @param component [Hash] The component hash containing font attributes
        # @param converter [BaseViewConverter] The converter instance to add modifier lines to
        def apply_font_modifiers(component, converter)
          # fontSize
          if component['fontSize']
            converter.add_modifier_line ".font(.system(size: #{component['fontSize'].to_i}))"
          end
          
          # font (bold対応)
          if component['font'] == 'bold'
            converter.add_modifier_line ".fontWeight(.bold)"
          elsif component['font']
            converter.add_modifier_line ".font(.custom(\"#{component['font']}\", size: #{(component['fontSize'] || 17).to_i}))"
          end
          
          # fontWeight (if specified separately)
          if component['fontWeight']
            weight = font_weight_to_swiftui(component['fontWeight'])
            converter.add_modifier_line ".fontWeight(#{weight})" if weight
          end
        end
        
        # Convert fontWeight string to SwiftUI font weight
        # @param weight [String] The weight string (e.g., "bold", "semibold", "light")
        # @return [String, nil] SwiftUI font weight or nil if not recognized
        def font_weight_to_swiftui(weight)
          case weight.to_s.downcase
          when 'ultralight', 'ultra-light'
            '.ultraLight'
          when 'thin'
            '.thin'
          when 'light'
            '.light'
          when 'regular', 'normal'
            '.regular'
          when 'medium'
            '.medium'
          when 'semibold', 'semi-bold'
            '.semibold'
          when 'bold'
            '.bold'
          when 'heavy'
            '.heavy'
          when 'black'
            '.black'
          else
            nil
          end
        end
        
        module_function :apply_font_modifiers, :font_weight_to_swiftui
      end
    end
  end
end