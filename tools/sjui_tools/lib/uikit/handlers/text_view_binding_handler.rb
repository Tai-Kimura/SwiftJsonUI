# frozen_string_literal: true

require_relative '../view_binding_handler'

module SjuiTools
  module UIKit
    class TextViewBindingHandler < ViewBindingHandler
      def handle_specific_binding(view_name, key, value)
        case key
        when "enabled"
          @binding_content << "        #{view_name}?.isEditable = #{value}\n"
        when "text"
          @binding_content << "        if !isInitialized {\n"
          @binding_content << "            #{view_name}?.text = #{value}\n"
          @binding_content << "        }\n"
        else
          return false
        end
        true
      end
    end
  end
end