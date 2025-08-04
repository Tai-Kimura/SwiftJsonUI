# frozen_string_literal: true

require_relative '../view_binding_handler'

module SjuiTools
  module Binding
    class LabelBindingHandler < ViewBindingHandler
      def handle_specific_binding(view_name, key, value)
        case key
        when "text"
          @reset_text_views[view_name] = {text: value}
        when "selected"
          @binding_content << "        #{view_name}?.selected = #{value}\n"
        when "font"
          @binding_content << "        let #{view_name}FontSize = (#{view_name}?.attributes[NSAttributedString.Key.font] as? UIFont ?? UIFont.systemFont(ofSize: 14.0)).pointSize\n"
          @binding_content << "        #{view_name}?.attributes[NSAttributedString.Key.font] = UIFont(name: #{value.gsub("'", "\"")}, size: #{view_name}FontSize)\n"
          @reset_text_views[view_name] = {} if @reset_text_views[view_name].nil?
        when "fontSize"
          @binding_content << "        let #{view_name}FontName = (#{view_name}?.attributes[NSAttributedString.Key.font] as? UIFont ?? UIFont.systemFont(ofSize: 14.0)).fontName\n"
          @binding_content << "        #{view_name}?.attributes[NSAttributedString.Key.font] = UIFont(name: #{view_name}FontName, size: #{value})\n"
          @reset_text_views[view_name] = {} if @reset_text_views[view_name].nil?
        when "fontColor"
          @binding_content << "        #{view_name}?.attributes[NSAttributedString.Key.foregroundColor] = #{value}\n"
          @reset_text_views[view_name] = {} if @reset_text_views[view_name].nil?
        when "highlightColor"
          @binding_content << "        #{view_name}?.highlightAttributes?[NSAttributedString.Key.foregroundColor] = #{value}\n"
          @reset_text_views[view_name] = {} if @reset_text_views[view_name].nil?
        when "hintColor"
          @binding_content << "        #{view_name}?.hintAttributes?[NSAttributedString.Key.foregroundColor] = #{value}\n"
          @reset_text_views[view_name] = {} if @reset_text_views[view_name].nil?
        when "partialAttributes"
          value.each_with_index do |pa, pa_index|
            if pa["range"].is_a?(Array)
              pa["range"].each_with_index do |r,r_index|
                if r.is_a?(String) && r.start_with?("@{")
                  t = r.sub(/^@\{/, "").sub(/\}$/, "").gsub(/'/, "\"")
                  @binding_content << "        #{view_name}?.partialAttributesJSON?[#{pa_index}][\"range\"][#{r_index}] = JSON(#{t.end_with?("!!") ? t.sub(/!!$/, "") : "#{t} ?? \"\""})\n"
                end
              end
            end
          end
        else
          return false
        end
        true
      end
    end
  end
end