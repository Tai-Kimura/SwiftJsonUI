# frozen_string_literal: true

require_relative '../view_binding_handler'

module SjuiTools
  module UIKit
    class ButtonBindingHandler < ViewBindingHandler
      def handle_specific_binding(view_name, key, value)
        case key
        when "enabled"
          @binding_content << "        #{view_name}.isEnabled = #{value}\n"
        when "text"
          @binding_content << "        if #available(iOS 15.0, *) {\n"
          @binding_content << "          #{view_name}.configuration?.attributedTitle = AttributedString(#{value})\n"
          @binding_content << "          #{view_name}.configurationUpdateHandler?(#{view_name})\n"
          @binding_content << "        } else {\n"
          @binding_content << "          #{view_name}.setTitle(#{value}, for: UIControl.State())\n"
          @binding_content << "        }\n"
        when "fontColor"
          @binding_content << "        #{view_name}.defaultFontColor = #{value}\n"
          @binding_content << "        if #available(iOS 15.0, *) {\n"
          @binding_content << "          #{view_name}.configurationUpdateHandler?(#{view_name})\n"
          @binding_content << "        }\n"
        when "disabledFontColor"
          @binding_content << "        #{view_name}.disabledFontColor = #{value}\n"
          @binding_content << "        if #available(iOS 15.0, *) {\n"
          @binding_content << "          #{view_name}.configurationUpdateHandler?(#{view_name})\n"
          @binding_content << "        }\n"
        else
          return false
        end
        true
      end
    end
  end
end