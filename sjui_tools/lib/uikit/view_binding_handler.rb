# frozen_string_literal: true

module SjuiTools
  module UIKit
    class ViewBindingHandler
      def initialize(binding_content_writer, reset_text_views, reset_constraint_views)
        @binding_content = binding_content_writer
        @reset_text_views = reset_text_views
        @reset_constraint_views = reset_constraint_views
      end

      # 共通のバインディング処理
      def handle_common_binding(view_name, key, value)
        case key
        when "canTap"
          @binding_content << "        #{view_name}?.canTap = #{value}\n"
          true
        when "visibility"
          @binding_content << "        #{view_name}?.visibility = #{value}\n"
          true
        when "background"
          @binding_content << "        #{view_name}?.setBackgroundColor(color: #{value})\n"
          true
        when "defaultBackground"
          @binding_content << "        #{view_name}?.defaultBackgroundColor = #{value}\n"
          true
        when "disabledBackground"
          @binding_content << "        #{view_name}?.disabledBackgroundColor = #{value}\n"
          true
        when "cornerRadius"
          @binding_content << "        #{view_name}?.layer.cornerRadius = #{value}\n"
          true
        when "borderColor"
          @binding_content << "        #{view_name}?.layer.borderColor = #{value}\n"
          true
        when "borderWidth"
          @binding_content << "        #{view_name}?.layer.borderWidth = #{value}\n"
          true
        when "clipToBounds"
          @binding_content << "        #{view_name}?.clipsToBounds = #{value}\n"
          true
        when "alpha"
          @binding_content << "        #{view_name}?.alpha = #{value}\n"
          true
        when "bindingScript"
          @binding_content << "        #{value}\n"
          true
        when "width"
          handle_width_binding(view_name, value)
          true
        when "height" 
          handle_height_binding(view_name, value)
          true
        when "topMargin" 
          @binding_content << "        #{view_name}?.constraintInfo?.topMargin = #{value}\n"
          @reset_constraint_views[view_name] = true
          true
        when "rightMargin" 
          @binding_content << "        #{view_name}?.constraintInfo?.rightMargin = #{value}\n"
          @reset_constraint_views[view_name] = true
          true
        when "bottomMargin" 
          @binding_content << "        #{view_name}?.constraintInfo?.bottomMargin = #{value}\n"
          @reset_constraint_views[view_name] = true
          true
        when "leftMargin" 
          @binding_content << "        #{view_name}?.constraintInfo?.leftMargin = #{value}\n"
          @reset_constraint_views[view_name] = true
          true
        when "widthWeight" 
          @binding_content << "        #{view_name}?.constraintInfo?.widthWeight = #{value}\n"
          @reset_constraint_views[view_name] = true
          true
        when "heightWeight" 
          @binding_content << "        #{view_name}?.constraintInfo?.heightWeight = #{value}\n"
          @reset_constraint_views[view_name] = true
          true
        else
          false # 処理されなかった場合
        end
      end

      # 各view typeで実装する必要がある抽象メソッド
      def handle_specific_binding(view_name, key, value)
        # デフォルトは何もしない（未知のview typeでも動作する）
        false
      end

      private

      def handle_width_binding(view_name, value)
        if value == "matchParent"
          @binding_content << "        #{view_name}?.constraintInfo?.width = UILayoutConstraintInfo.LayoutParams.matchParent\n"
        elsif value == "wrapContent"
          @binding_content << "        #{view_name}?.constraintInfo?.width = UILayoutConstraintInfo.LayoutParams.wrapContent\n"
        else
          @binding_content << "        #{view_name}?.constraintInfo?.width = #{value}\n"
        end
        @reset_constraint_views[view_name] = true    
      end

      def handle_height_binding(view_name, value)
        if value == "matchParent"
          @binding_content << "        #{view_name}?.constraintInfo?.height = UILayoutConstraintInfo.LayoutParams.matchParent\n"
        elsif value == "wrapContent"
          @binding_content << "        #{view_name}?.constraintInfo?.height = UILayoutConstraintInfo.LayoutParams.wrapContent\n"
        else
          @binding_content << "        #{view_name}?.constraintInfo?.height = #{value}\n"
        end 
        @reset_constraint_views[view_name] = true
      end
    end
  end
end