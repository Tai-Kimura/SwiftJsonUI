require File.expand_path(File.dirname(__FILE__)) + "/../view_binding_handler"

class IconLabelBindingHandler < ViewBindingHandler
  def handle_specific_binding(view_name, key, value)
    case key
    when "text"
      @binding_content << "        #{view_name}.label.applyAttributedText(#{value})\n"
    when "selected"
      @binding_content << "        #{view_name}.isSelected = #{value}\n"
    else
      return false
    end
    true
  end
end