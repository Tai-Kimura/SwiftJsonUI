require File.expand_path(File.dirname(__FILE__)) + "/../view_binding_handler"

class ScrollBindingHandler < ViewBindingHandler
  def handle_specific_binding(view_name, key, value)
    case key
    when "scrollEnabled"
      @binding_content << "        #{view_name}?.isScrollEnabled = #{value}\n"
    when "maxZoom"
      @binding_content << "        #{view_name}?.maximumZoomScale = #{value}\n"
    when "minZoom"
      @binding_content << "        #{view_name}?.minimumZoomScale = #{value}\n"
    else
      return false
    end
    true
  end
end