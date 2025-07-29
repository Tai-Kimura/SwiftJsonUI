require File.expand_path(File.dirname(__FILE__)) + "/../view_binding_handler"

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

class TextViewBindingHandler < ViewBindingHandler
  def handle_specific_binding(view_name, key, value)
    case key
    when "enabled"
      @binding_content << "        #{view_name}?.isEditable = #{value}\n"
    when "text"
      @binding_content << "        if !isInitialized {\n"
      @binding_content << "            #{view_name}?.text = #{value}\n"
      @binding_content << "        }\n"
    else
      return false
    end
    true
  end
end