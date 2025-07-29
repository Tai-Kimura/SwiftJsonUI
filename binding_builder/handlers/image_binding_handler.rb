require File.expand_path(File.dirname(__FILE__)) + "/../view_binding_handler"

class ImageBindingHandler < ViewBindingHandler
  def handle_specific_binding(view_name, key, value)
    case key
    when "srcName"
      if value.end_with?("!!")
        v = value.sub(/!!$/, "")
        @binding_content << "        #{view_name}?.image = UIImage(named: #{v})\n"
      else
        @binding_content << "        #{view_name}?.image = !(#{value} ?? \"\").isEmpty ? UIImage(named: #{value}!) : nil\n"
      end
    when "highlightSrcName"
      if value.end_with?("!!")
        v = value.sub(/!!$/, "")
        @binding_content << "        #{view_name}?.highlightedImage = UIImage(named: #{v})\n"
      else
        @binding_content << "        #{view_name}?.highlightedImage = #{value} != nil ? UIImage(named: #{value}!) : nil\n"
      end
    when "src"
      @binding_content << "        #{view_name}?.image = #{value}\n"
    when "highlightSrc"
      @binding_content << "        #{view_name}?.highlightedImage = #{value}\n"
    when "contentMode"
      @binding_content << "        #{view_name}?.contentMode = #{value}\n"
    else
      return false
    end
    true
  end
end