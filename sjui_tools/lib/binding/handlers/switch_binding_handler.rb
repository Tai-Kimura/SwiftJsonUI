# frozen_string_literal: true

require_relative '../view_binding_handler'

module SjuiTools
  module Binding
    class SwitchBindingHandler < ViewBindingHandler
      def handle_specific_binding(view_name, key, value)
        case key
        when "on"
          @binding_content << "        #{view_name}?.isOn = #{value}\n"
        when "enabled"
          @binding_content << "        #{view_name}?.isEnabled = #{value}\n"
        else
          return false
        end
        true
      end
    end
  end
end