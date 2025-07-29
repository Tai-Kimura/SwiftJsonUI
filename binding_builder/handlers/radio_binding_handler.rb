require File.expand_path(File.dirname(__FILE__)) + "/../view_binding_handler"

class RadioBindingHandler < ViewBindingHandler
  def handle_specific_binding(view_name, key, value)
    case key
    when "check"
      @binding_content << "        #{view_name}?.onCheck()\n"
    else
      return false
    end
    true
  end
end