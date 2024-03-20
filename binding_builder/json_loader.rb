require "json"
require "time"
require File.expand_path(File.dirname(__FILE__)) + "/string_module"

class JsonLoader

  @@view_type_set = {
    "View": "SJUIView",
    "SafeAreaView": "SJUIView",
    "GradientView": "GradientView",
    "Blur": "SJUIVisualEffectView",
    "CircleView": "SJUICircleView",
    "Scroll": "SJUIScrollView",
    "Table": "SJUITableView",
    "Collection": "SJUICollectionView",
    "Segment": "SJUISegmentedControl",
    "Label": "SJUILabel",
    "IconLabel": "SJUILabelWithIcon",
    "Button": "SJUIButton",
    "Image": "SJUIImageView",
    "NetworkImage": "NetworkImageView",
    "CircleImage": "CircleImageView",
    "Web": "WKWebView",
    "TextField": "SJUITextField",
    "TextView": "SJUITextView",
    "Switch": "SJUISwitch",
    "Radio": "SJUIRadioButton",
    "Check": "SJUICheckBox",
    "Progress": "UIProgressView",
    "Slider": "UISlider",
    "SelectBox": "SJUISelectBox",
    "Indicator": "UIActivityIndicatorView"
  }

  @@ignore_id_set = {
  }

  @@ignore_data_set = {
  }

  def initialize project_root_path
    @view_path = File.expand_path(File.dirname(__FILE__)) + "/#{project_root_path}/View"
    @layout_path = File.expand_path(File.dirname(__FILE__)) + "/#{project_root_path}/Layouts"
    @style_path = File.expand_path(File.dirname(__FILE__)) + "/#{project_root_path}/Styles"
    @binding_path = File.expand_path(File.dirname(__FILE__)) + "/#{project_root_path}/Bindings"
    @including_files = {}
  end

  def self.view_type_set
    @@view_type_set
  end

  def start_analyze
    last_updated = nil
    File.open(File.expand_path(File.dirname(__FILE__)) + "/last_updated.txt", "r") do |file|
      begin
        last_updated = Time.parse(file.read)
      rescue => ex
        puts ex.message
      end
    end
    last_including_files = {}
    File.open(File.expand_path(File.dirname(__FILE__)) + "/including.json", "r") do |file|
      last_including_files = JSON.load(file)
    end
    puts "last_updated: #{last_updated}"
    Dir.glob("#{@layout_path}/*.json") do |file_path|
      puts file_path
      file_name = file_path.split("/")[-1].split(".")[0]
      stat = File::Stat.new(file_path)
      puts "file updated: #{stat.mtime}"
      if !last_updated.nil? && stat.mtime <= last_updated
        including_files = last_including_files[file_name]
        next if including_files.nil?
        should_update = false
        including_files.each do |f|
          included_file_path = "#{@layout_path}/_#{f}.json"
          stat = File::Stat.new(included_file_path)
          if stat.mtime > last_updated
            should_update = true
            break
          end
        end
        if !should_update
          @including_files[file_name] = last_including_files[file_name]
          next
        end
      end
      next if file_name.start_with?("_")
      puts "Update Binding"
      @base_name = "#{file_name.camelize}"
      @binding_class_name = "#{@base_name}Binding"
      @binding_file_name = "#{@binding_class_name}.swift"
      puts @binding_file_name
      @binding_file_path = "#{@binding_path}/#{@binding_file_name}"
      if File.exists? @binding_file_path
        File.delete(@binding_file_path)
      end
      @super_binding = "Binding"
      if File.exists?("#{@view_path}/#{@base_name}/#{@base_name}ViewController.swift")
        @super_binding = "BaseBinding"
      end
      @binding_content = ""
      @data_sets = [JSON.parse({"name": "isInitialized", "class": "Bool", "defaultValue": "true"}.to_json)]
      @ui_control_events = []
      @binding_processes_group = {}
      @import_modules = {}
      @reset_constraint_views = {}
      File.open(file_path) do |file|
        json = JSON.load(file)
        analyze_json(file_name, json)
      end
      import_module_content = "import UIKit\nimport SwiftJsonUI\n"
      @import_modules.each do |import_module, v|
        import_module_content << "import #{import_module}\n"
      end
      data_content = ""
      @data_sets.each do |data|
        next if @super_binding != "Binding" && !@@ignore_data_set[data["name"].to_sym].nil?
        modifier = data["modifier"].nil? ? "var" : data["modifier"]
        if data["defaultValue"].nil?
          data_content << "    #{modifier} #{data["name"]}: #{data["class"]}?\n"
        else
          data_content << "    #{modifier} #{data["name"]}: #{data["class"]}#{data["optional"] ? "?" : ""} = #{data["defaultValue"].to_s.gsub(/'/, "\"")}\n"
        end
      end
      @binding_content = "#{import_module_content}\nclass #{@binding_class_name}: #{@super_binding} {\n" + data_content + @binding_content
      if @ui_control_events.size > 0
        @binding_content << "\n"
        @binding_content << "    override func bindView() {\n"
        @binding_content << "        super.bindView()\n"
        @ui_control_events.each do |ce|
          if ce[:event] == "longPress"
            @binding_content << "        #{ce[:view_name]}?.#{ce[:event]}(duration: #{ce[:duration]}){ [weak self] gesture in self?.#{ce[:value]}?(gesture) }\n"
            @binding_content << "        #{ce[:view_name]}?.isUserInteractionEnabled = true\n"
          else
            @binding_content << "        #{ce[:view_name]}?.#{ce[:event]}{ [weak self] gesture in self?.#{ce[:value]}?(gesture) }\n"
            @binding_content << "        #{ce[:view_name]}?.isUserInteractionEnabled = true\n"
          end
        end
        @binding_content << "    }\n"
      end
      @binding_processes_group.each do |group,value|
        @binding_content << "\n"
        @reset_constraint_views = {}
        @reset_text_views = {}
        @binding_content << "    func invalidate#{group.capitalize.camelize}(resetForm: Bool = false, formInitialized: Bool = false) {\n"
        @binding_content << "        if resetForm {\n"
        @binding_content << "            isInitialized = false\n"
        @binding_content << "        }\n"
        value.each do |binding_process|
          analyze_binding_process binding_process
        end
        @reset_text_views.each do |key, value|
          text = value[:text].nil? ? "#{key}?.attributedText?.string" : value[:text]
          @binding_content << "        #{key}?.linkable ?? false ? #{key}?.applyLinkableAttributedText(#{text}) : #{key}?.applyAttributedText(#{text})\n"
        end
        @reset_constraint_views.keys.each do |key|
          @binding_content << "        #{key}.resetConstraintInfo()\n"
        end
        @binding_content << "        if formInitialized {\n"
        @binding_content << "            isInitialized = true\n"
        @binding_content << "        }\n"
        @binding_content << "    }\n"
      end
      @binding_content << "}"
      File.open(@binding_file_path, "w") do |binding_file|
        binding_file.write(@binding_content)
      end
    end
    File.open(File.expand_path(File.dirname(__FILE__)) + "/including.json", "w") do |file|
      file.write(@including_files.to_json)
    end
    File.open(File.expand_path(File.dirname(__FILE__)) + "/last_updated.txt", "w") do |file|
      file.write(Time.now)
    end 
    File.open(File.expand_path(File.dirname(__FILE__)) + "/last_updated.txt", "w") do |file|
      file.write(Time.now)
    end
  end

  def analyze_json file_name, loaded_json
    json = loaded_json
    current_view = {"name": "", "type": ""}
    unless json["style"].nil?
      file_path = "#{@style_path}/#{json["style"]}.json"
      File.open(file_path, "r") do |file|
        json_string = file.read
        style_json = JSON.parse(json_string)
        json = json.merge(style_json)
      end
    end
    json.each do |key,value|
      case key
      when "data"
        @data_sets += value
      when "type"
        case value
        when "Map"
          @import_modules["GoogleMaps"] = true
        when "Web"
          @import_modules["WebKit"] = true
        end
        current_view["type"] = value
      when "id"
        puts "id: #{value}"
        view_type = @@view_type_set[json["type"].to_sym]
        raise "View Type Not found" if view_type.nil?
        variable_name = value.camelize
        variable_name[0] = variable_name[0].chr.downcase
        current_view["name"] = variable_name
        next if @super_binding != "Binding" && !@@ignore_id_set[value.to_sym].nil?
        @binding_content << "    weak var #{variable_name}: #{view_type}!\n"
      when "child"
        value.each do |child_json|
          analyze_json(file_name, child_json)
        end
      when "include"
        if @including_files[file_name].nil?
          @including_files[file_name] = [value]
        else
          @including_files[file_name] << value
          @including_files[file_name].uniq!
        end
        file_path = "#{@layout_path}/_#{value}.json"
        if !File.exists?(file_path)
          file_path = "#{@layout_path}/#{value}.json"
        end
        File.open(file_path, "r") do |file|
          json_string = file.read
          unless json["variables"].nil?
            json["variables"].each do |k,v|
              puts k
              puts v
              json_string.gsub!(k,v.to_s)
            end
          end
          included_json = JSON.parse(json_string)
          analyze_json(file_name, included_json)
        end
      when "onClick"
        @ui_control_events << {view_name: current_view["name"], value: value.sub(/^@\{/, "").sub(/\}$/, ""), event: "click"}
      when "onLongPress"
        @ui_control_events << {view_name: current_view["name"], value: value["closure"].sub(/^@\{/, "").sub(/\}$/, ""), duration: value["duration"], event: "longPress"}
      when "onPan"
        @ui_control_events << {view_name: current_view["name"], value: value.sub(/^@\{/, "").sub(/\}$/, ""), event: "pan"}
      when "onPinch"
        @ui_control_events << {view_name: current_view["name"], value: value.sub(/^@\{/, "").sub(/\}$/, ""), event: "pinch"}
      else
        if value.is_a?(String) && value.start_with?("@{")
          v = value.sub(/^@\{/, "").sub(/\}$/, "")
          group_names = json["binding_group"].nil? ? ["all",""] : ["all"] + json["binding_group"]
          group_names.each do |group_name|
            group = @binding_processes_group[group_name]
            group = [] if group.nil?
            unless json["partialAttributes"].nil?
              group << {"view": current_view, "key": "partialAttributes", "value": json["partialAttributes"]} 
            end
            group << {"view": current_view, "key": key, "value": v} 
            @binding_processes_group[group_name] = group
          end
        end
      end
    end
  end

  def analyze_binding_process binding_process
    view = binding_process[:view]
    view_name = view["name"]
    puts view
    raise "View Id should be set. #{binding_process}" if view_name.nil?
    key = binding_process[:key]

    value = binding_process[:value]
    if value.is_a?(String)
      value = value.gsub(/this/, view["name"]).gsub(/'/, "\"")
    end
    case key
    when "canTap"
      @binding_content << "        #{view_name}?.canTap = #{value}\n"
    when "visibility"
      @binding_content << "        #{view_name}?.visibility = #{value}\n"
    when "background"
      @binding_content << "        #{view_name}?.setBackgroundColor(color: #{value})\n"
    when "defaultBackground"
      @binding_content << "        #{view_name}?.defaultBackgroundColor = #{value}\n"
    when "disabledBackground"
      @binding_content << "        #{view_name}?.disabledBackgroundColor = #{value}\n"
    when "cornerRadius"
      @binding_content << "        #{view_name}?.layer.cornerRadius = #{value}\n"
    when "borderColor"
      @binding_content << "        #{view_name}?.layer.borderColor = #{value}\n"
    when "borderWidth"
      @binding_content << "        #{view_name}?.layer.borderWidth = #{value}\n"
    when "clipToBounds"
      @binding_content << "        #{view_name}?.clipsToBounds = #{value}\n"
    when "alpha"
      @binding_content << "        #{view_name}?.alpha = #{value}\n"
    when "bindingScript"
      @binding_content << "        #{value}\n"
    when "width"
      if value == "matchParent"
        @binding_content << "        #{view_name}?.constraintInfo?.width = UILayoutConstraintInfo.LayoutParams.matchParent\n"
      elsif value == "wrapContent"
        @binding_content << "        #{view_name}?.constraintInfo?.width = UILayoutConstraintInfo.LayoutParams.wrapContent\n"
      else
        @binding_content << "        #{view_name}?.constraintInfo?.width = #{value}\n"
      end
      @reset_constraint_views[view_name] = true    
    when "height" 
      if value == "matchParent"
        @binding_content << "        #{view_name}?.constraintInfo?.height = UILayoutConstraintInfo.LayoutParams.matchParent\n"
      elsif value == "wrapContent"
        @binding_content << "        #{view_name}?.constraintInfo?.height = UILayoutConstraintInfo.LayoutParams.wrapContent\n"
      else
        @binding_content << "        #{view_name}?.constraintInfo?.height = #{value}\n"
      end 
      @reset_constraint_views[view_name] = true
    when "topMargin" 
      @binding_content << "        #{view_name}?.constraintInfo?.topMargin = #{value}\n"
      @reset_constraint_views[view_name] = true
    when "rightMargin" 
      @binding_content << "        #{view_name}?.constraintInfo?.rightMargin = #{value}\n"
      @reset_constraint_views[view_name] = true
    when "bottomMargin" 
      @binding_content << "        #{view_name}?.constraintInfo?.bottomMargin = #{value}\n"
      @reset_constraint_views[view_name] = true
    when "leftMargin" 
      @binding_content << "        #{view_name}?.constraintInfo?.leftMargin = #{value}\n"
      @reset_constraint_views[view_name] = true
    when "widthWeight" 
      @binding_content << "        #{view_name}?.constraintInfo?.widthWeight = #{value}\n"
      @reset_constraint_views[view_name] = true
    when "heightWeight" 
      @binding_content << "        #{view_name}?.constraintInfo?.heightWeight = #{value}\n"
      @reset_constraint_views[view_name] = true
    else
      case view["type"]
      when "Button"
        case key
        when "enabled"
          @binding_content << "        #{view_name}.isEnabled = #{value}\n"
        when "text"
          @binding_content << "        if #available(iOS 15.0, *) {\n"
          @binding_content << "          #{view_name}.configuration?.attributedTitle = AttributedString(#{value})\n"
          @binding_content << "          #{view_name}.configurationUpdateHandler?(#{view_name})\n"
          @binding_content << "        } else {\n"
          @binding_content << "          #{view_name}.setTitle(#{value}, for: UIControl.State())\n"
          @binding_content << "        }\n"
        when "fontColor"
          @binding_content << "        #{view_name}.defaultFontColor = #{value}\n"
          @binding_content << "        if #available(iOS 15.0, *) {\n"
          @binding_content << "          #{view_name}.configurationUpdateHandler?(#{view_name})\n"
          @binding_content << "        }\n"
        when "disabledFontColor"
          @binding_content << "        #{view_name}.disabledFontColor = #{value}\n"
          @binding_content << "        if #available(iOS 15.0, *) {\n"
          @binding_content << "          #{view_name}.configurationUpdateHandler?(#{view_name})\n"
          @binding_content << "        }\n"
        end
      when "Check"
        case key
        when "check"
          @binding_content << "        #{view_name}.setCheck(#{value})\n"
        end
      when "NetworkImage", "CircleImage"
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
        end
      when "IconLabel"
        case key
        when "text"
          @binding_content << "        #{view_name}.label.applyAttributedText(#{value})\n"
        when "selected"
          @binding_content << "        #{view_name}.isSelected = #{value}\n"
        end
      when "Image"
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
        end
      when "Label"
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
        end
      when "Radio"
        case key
        when "check"
          @binding_content << "        #{view_name}?.onCheck()\n"
        end
      when "Scroll"
        case key
        when "scrollEnabled"
          @binding_content << "        #{view_name}?.isScrollEnabled = #{value}\n"
        when "maxZoom"
          @binding_content << "        #{view_name}?.maximumZoomScale = #{value}\n"
        when "minZoom"
          @binding_content << "        #{view_name}?.minimumZoomScale = #{value}\n"
        end
      when "SelectBox"
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
        end
      when "Switch"
        case key
        when "on"
          @binding_content << "        #{view_name}?.isOn = #{value}\n"
        when "enabled"
          @binding_content << "        #{view_name}?.isEnabled = #{value}\n"
        end
      when "TextField"
        case key
        when "enabled"
          @binding_content << "        #{view_name}?.isEnabled = #{value}\n"
        when "text"
          @binding_content << "        if !isInitialized {\n"
          @binding_content << "            #{view_name}?.text = #{value}\n"
          @binding_content << "        }\n"
        when "secure"
          @binding_content << "        #{view_name}?.isSecureTextEntry = #{value}\n"
        when "contentType"
          @binding_content << "        #{view_name}?.textContentType = #{value}\n"
        end
      when "TextView"
        case key
        when "enabled"
          @binding_content << "        #{view_name}?.isEditable = #{value}\n"
        when "text"
          @binding_content << "        if !isInitialized {\n"
          @binding_content << "            #{view_name}?.text = #{value}\n"
          @binding_content << "        }\n"
        end
      end
    end
  end
end