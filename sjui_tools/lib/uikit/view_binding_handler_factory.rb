# frozen_string_literal: true

require_relative 'handlers/button_binding_handler'
require_relative 'handlers/check_binding_handler'
require_relative 'handlers/icon_label_binding_handler'
require_relative 'handlers/image_binding_handler'
require_relative 'handlers/label_binding_handler'
require_relative 'handlers/network_image_binding_handler'
require_relative 'handlers/radio_binding_handler'
require_relative 'handlers/scroll_binding_handler'
require_relative 'handlers/select_box_binding_handler'
require_relative 'handlers/switch_binding_handler'
require_relative 'handlers/text_field_binding_handler'
require_relative 'handlers/text_view_binding_handler'

module SjuiTools
  module UIKit
    class ViewBindingHandlerFactory
      def self.create_handler(view_type, binding_content, reset_text_views, reset_constraint_views)
        case view_type
        when "Button"
          ButtonBindingHandler.new(binding_content, reset_text_views, reset_constraint_views)
        when "Check"
          CheckBindingHandler.new(binding_content, reset_text_views, reset_constraint_views)
        when "NetworkImage", "CircleImage"
          NetworkImageBindingHandler.new(binding_content, reset_text_views, reset_constraint_views)
        when "IconLabel"
          IconLabelBindingHandler.new(binding_content, reset_text_views, reset_constraint_views)
        when "Image"
          ImageBindingHandler.new(binding_content, reset_text_views, reset_constraint_views)
        when "Label"
          LabelBindingHandler.new(binding_content, reset_text_views, reset_constraint_views)
        when "Radio"
          RadioBindingHandler.new(binding_content, reset_text_views, reset_constraint_views)
        when "Scroll"
          ScrollBindingHandler.new(binding_content, reset_text_views, reset_constraint_views)
        when "SelectBox"
          SelectBoxBindingHandler.new(binding_content, reset_text_views, reset_constraint_views)
        when "Switch"
          SwitchBindingHandler.new(binding_content, reset_text_views, reset_constraint_views)
        when "TextField"
          TextFieldBindingHandler.new(binding_content, reset_text_views, reset_constraint_views)
        when "TextView"
          TextViewBindingHandler.new(binding_content, reset_text_views, reset_constraint_views)
        else
          # デフォルトは共通処理のみのハンドラー
          ViewBindingHandler.new(binding_content, reset_text_views, reset_constraint_views)
        end
      end
    end
  end
end