# frozen_string_literal: true

require_relative '../view_binding_handler'

module SjuiTools
  module UIKit
    class SelectBoxBindingHandler < ViewBindingHandler
      def handle_specific_binding(view_name, key, value)
        case key
        when "selectedIndex"
          @binding_content << "        if !isInitialized {\n"
          @binding_content << "            #{view_name}?.selectedIndex = #{view_name}?.hasPrompt ?? false && !#{view_name}.includePromptWhenDataBinding ? #{value} + 1 : #{value}\n"
          @binding_content << "        }\n"
        when "selectedItem"
          @binding_content << "        if !isInitialized {\n"
          @binding_content << "            #{view_name}.selectedIndex = #{view_name}?.items.firstIndex(where: {$0 == #{value}})\n"
          @binding_content << "        }\n"
        when "selectedDate"
          @binding_content << "        if !isInitialized {\n"
          @binding_content << "            #{view_name}?.selectedDate = #{value}\n"
          @binding_content << "        }\n"
        when "items"
          @binding_content << "        #{view_name}?.items = #{value}\n"
        when "minimumDate"
          @binding_content << "        #{view_name}?.minimumDate = #{value}\n"
        when "maximumDate"
          @binding_content << "        #{view_name}?.maximumDate = #{value}\n"
        else
          return false
        end
        true
      end
    end
  end
end