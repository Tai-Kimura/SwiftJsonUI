# frozen_string_literal: true

module SjuiTools
  module Binding
    class UIControlEventManager
      def initialize
        @ui_control_events = []
      end

      def reset
        @ui_control_events = []
      end

      def add_click_event(view_name, value)
        return if value == "nil"
        @ui_control_events << {
          view_name: view_name, 
          value: value.sub(/^@\{/, "").sub(/\}$/, ""), 
          event: "click"
        }
      end

      def add_long_press_event(view_name, value)
        return if value == "nil"
        @ui_control_events << {
          view_name: view_name,
          value: value["closure"].sub(/^@\{/, "").sub(/\}$/, ""),
          duration: value["duration"],
          event: "longPress"
        }
      end

      def add_pan_event(view_name, value)
        return if value == "nil"
        @ui_control_events << {
          view_name: view_name,
          value: value.sub(/^@\{/, "").sub(/\}$/, ""),
          event: "pan"
        }
      end

      def add_pinch_event(view_name, value)
        return if value == "nil"
        @ui_control_events << {
          view_name: view_name,
          value: value.sub(/^@\{/, "").sub(/\}$/, ""),
          event: "pinch"
        }
      end

      def generate_bind_view_method
        return "" if @ui_control_events.size == 0

        content = String.new("\n")
        content << "    override func bindView() {\n"
        content << "        super.bindView()\n"
        
        @ui_control_events.each do |ce|
          if ce[:event] == "longPress"
            content << "        #{ce[:view_name]}?.#{ce[:event]}(duration: #{ce[:duration]}){ [weak self] gesture in self?.#{ce[:value]}?(gesture) }\n"
            content << "        #{ce[:view_name]}?.isUserInteractionEnabled = true\n"
          else
            content << "        #{ce[:view_name]}?.#{ce[:event]}{ [weak self] gesture in self?.#{ce[:value]}?(gesture) }\n"
            content << "        #{ce[:view_name]}?.isUserInteractionEnabled = true\n"
          end
        end
        
        content << "    }\n"
        content
      end
    end
  end
end