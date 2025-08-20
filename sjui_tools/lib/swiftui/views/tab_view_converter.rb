# frozen_string_literal: true

require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class TabViewConverter < BaseViewConverter
        def initialize(component, indent_level = 0, action_manager = nil, converter_factory = nil, view_registry = nil, binding_registry = nil)
          super(component, indent_level, action_manager, binding_registry)
          @converter_factory = converter_factory
          @view_registry = view_registry
        end
        
        def convert
          tabs = @component['tabs'] || []
          selected_index = @component['selectedTabIndex'] || 0
          
          # Generate state variable for selection
          add_line "TabView {"
          
          indent do
            tabs.each_with_index do |tab, index|
              # Add tab content
              if tab['child'] && tab['child'].is_a?(Array)
                tab['child'].each do |child|
                  child_converter = @converter_factory.create_converter(child, @indent_level + 1, @action_manager, @converter_factory, @view_registry)
                  child_code = child_converter.convert
                  child_code.split("\n").each { |line| @generated_code << line }
                end
              end
              
              # Add tab item modifier
              indent_string = '    ' * (@indent_level + 1)
              add_line "#{indent_string}.tabItem {"
              indent do
                indent do
                  add_line "Label(\"#{tab['title'] || "Tab #{index + 1}"}\", systemImage: \"#{tab['icon'] || 'circle'}\")"
                end
              end
              add_line "#{indent_string}}"
              
              # Add tag for selection
              add_line "#{indent_string}.tag(#{index})"
            end
          end
          
          add_line "}"
          
          apply_modifiers
          generated_code
        end
      end
    end
  end
end