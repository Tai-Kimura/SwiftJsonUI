# frozen_string_literal: true

require_relative '../view_binding_handler'

module SjuiTools
  module UIKit
    class CheckBindingHandler < ViewBindingHandler
      def handle_specific_binding(view_name, key, value)
        case key
        when "check"
          @binding_content << "        #{view_name}.setCheck(#{value})\n"
        else
          return false
        end
        true
      end
    end
  end
end