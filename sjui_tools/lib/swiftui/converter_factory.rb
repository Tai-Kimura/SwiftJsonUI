# frozen_string_literal: true

require_relative 'views/label_converter'
require_relative 'views/button_converter'
require_relative 'views/view_converter'
require_relative 'views/textfield_converter'
require_relative 'views/textview_converter'
require_relative 'views/image_converter'
require_relative 'views/scrollview_converter'
require_relative 'views/segment_converter'
require_relative 'views/progress_converter'
require_relative 'views/slider_converter'
require_relative 'views/indicator_converter'
require_relative 'views/table_converter'
require_relative 'views/collection_converter'
require_relative 'views/web_converter'
require_relative 'views/radio_converter'
require_relative 'views/selectbox_converter'
require_relative 'views/network_image_converter'
require_relative 'views/blur_converter'
require_relative 'views/gradient_view_converter'
require_relative 'views/icon_label_converter'
require_relative 'views/dynamic_component_converter'
require_relative 'views/toggle_converter'
require_relative 'views/include_converter'
require_relative 'view_registry'

module SjuiTools
  module SwiftUI
    class ConverterFactory
      def initialize(binding_registry = nil)
        @view_registry = ViewRegistry.new
        @binding_registry = binding_registry
      end
      
      def create_converter(component, indent_level = 0, action_manager = nil, converter_factory = nil, view_registry = nil)
        component_type = component['type']
        registry = view_registry || @view_registry
        
        case component_type
        when 'Label', 'Text'
          Views::LabelConverter.new(component, indent_level, action_manager, @binding_registry)
        when 'IconLabel'
          Views::IconLabelConverter.new(component, indent_level, action_manager, @binding_registry)
        when 'Button'
          Views::ButtonConverter.new(component, indent_level, action_manager, @binding_registry)
        when 'View', 'SafeAreaView'
          Views::ViewConverter.new(component, indent_level, action_manager, self, registry, @binding_registry)
        when 'GradientView'
          Views::GradientViewConverter.new(component, indent_level, action_manager, self, registry, @binding_registry)
        when 'Blur'
          Views::BlurConverter.new(component, indent_level, action_manager, self, registry, @binding_registry)
        when 'TextField'
          Views::TextFieldConverter.new(component, indent_level, action_manager, @binding_registry)
        when 'Image', 'CircleImage'
          Views::ImageConverter.new(component, indent_level, action_manager, @binding_registry)
        when 'NetworkImage'
          Views::NetworkImageConverter.new(component, indent_level, action_manager, @binding_registry)
        when 'Scroll', 'ScrollView'
          Views::ScrollViewConverter.new(component, indent_level, action_manager, self, registry, @binding_registry)
        when 'TextView'
          Views::TextViewConverter.new(component, indent_level, action_manager, @binding_registry)
        when 'Switch', 'Toggle'
          Views::ToggleConverter.new(component, indent_level, action_manager, @binding_registry)
        when 'Check', 'Checkbox'
          Views::ToggleConverter.new(component, indent_level, action_manager, @binding_registry)
        when 'Radio'
          Views::RadioConverter.new(component, indent_level, action_manager, @binding_registry)
        when 'Segment'
          Views::SegmentConverter.new(component, indent_level, action_manager, @binding_registry)
        when 'Progress'
          Views::ProgressConverter.new(component, indent_level, action_manager, @binding_registry)
        when 'Slider'
          Views::SliderConverter.new(component, indent_level, action_manager, @binding_registry)
        when 'Indicator'
          Views::IndicatorConverter.new(component, indent_level, action_manager, @binding_registry)
        when 'Table'
          Views::TableConverter.new(component, indent_level, action_manager, @binding_registry)
        when 'Collection'
          Views::CollectionConverter.new(component, indent_level, action_manager, @binding_registry)
        when 'SelectBox'
          Views::SelectBoxConverter.new(component, indent_level, action_manager, @binding_registry)
        when 'Web'
          Views::WebConverter.new(component, indent_level, action_manager, @binding_registry)
        when 'DynamicComponent'
          Views::DynamicComponentConverter.new(component, indent_level, action_manager, @binding_registry)
        when 'Include'
          Views::IncludeConverter.new(component, indent_level, action_manager, @binding_registry)
        else
          # デフォルトコンバーター
          DefaultConverter.new(component, indent_level, action_manager, @binding_registry)
        end
      end
    end

    # 追加のコンバータークラス
    class SwitchConverter < Views::BaseViewConverter
      def convert
        id = @component['id'] || "toggle"
        
        # Create @State variable name
        state_var = "#{id}IsOn"
        
        # Add state variable to requirements
        @state_variables ||= []
        @state_variables << "@State private var #{state_var} = false"
        
        add_line "Toggle(\"\", isOn: $#{state_var})"
        add_modifier_line ".labelsHidden()"
        
        # onChange handler
        if @component['onValueChanged'] && @action_manager
          handler_name = @action_manager.register_action(@component['onValueChanged'], 'switch')
          add_modifier_line ".onChange(of: #{state_var}) { newValue in"
          indent do
            add_line "#{handler_name}()"
          end
          add_line "}"
        end
        
        apply_modifiers
        generated_code
      end
    end

    class CheckboxConverter < Views::BaseViewConverter
      def convert
        id = @component['id'] || "checkbox"
        
        # Create @State variable name
        state_var = "#{id}IsChecked"
        
        # Add state variable to requirements
        @state_variables ||= []
        @state_variables << "@State private var #{state_var} = false"
        
        add_line "Image(systemName: #{state_var} ? \"checkmark.square.fill\" : \"square\")"
        add_modifier_line ".onTapGesture {"
        indent do
          add_line "#{state_var}.toggle()"
          if @component['onclick'] && @action_manager
            handler_name = @action_manager.register_action(@component['onclick'], 'checkbox')
            if @component['onclick'].end_with?(':')
              add_line "viewModel.#{handler_name}(#{state_var})"
            else
              add_line "viewModel.#{handler_name}()"
            end
          end
        end
        add_line "}"
        
        apply_modifiers
        generated_code
      end
    end

    class DefaultConverter < Views::BaseViewConverter
      def convert
        add_line "Text(\"Unsupported component: #{@component['type']}\")"
        add_modifier_line ".foregroundColor(.red)"
        
        apply_modifiers
        generated_code
      end
    end
  end
end