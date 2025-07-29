require File.expand_path(File.dirname(__FILE__)) + "/../view_binding_handler"

class NetworkImageBindingHandler < ViewBindingHandler
  def handle_specific_binding(view_name, key, value)
    case key
    when "url"
      if value.end_with?("!!")
        v = value.sub(/!!$/, "")
        @binding_content << "        #{view_name}.setImageURL(string: #{v}, headers: #{v}.isMatch(pattern:  \"^\\\(Network.HttpHost)\") || #{v}.isMatch(pattern:  \"^\\\(AppUtil.RegacyHttpHost)\") ? Network.headers : nil)\n"
      else
        @binding_content << "        #{view_name}.setImageURL(string: #{value}, headers: #{value}?.isMatch(pattern:  \"^\\\(Network.HttpHost)\") ?? false  || #{value}?.isMatch(pattern:  \"^\\\(AppUtil.RegacyHttpHost)\") ?? false ? Network.headers : nil)\n"
      end
    when "contentMode"
      @binding_content << "        #{view_name}?.contentMode = #{value}\n"
    else
      return false
    end
    true
  end
end

# CircleImageも同じ処理なのでエイリアスとして使用
CircleImageBindingHandler = NetworkImageBindingHandler