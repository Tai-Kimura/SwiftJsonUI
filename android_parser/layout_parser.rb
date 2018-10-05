require './parser'
require './style_parser'
class LayoutParser < Parser

  def self.parse_all
    layout_dir = "layout"
    dirname = Parser.results_path + layout_dir
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
    files = Dir[Parser.root_path + "/*.json"]
    files.each do |file|
      parser = LayoutParser.new(file)
      parser.parse(layout_dir + "/")
    end
  end

  def initialize file
    super
    xml_decl = @xml.xml_decl
    xml_decl.version = 1.0
    xml_decl.encoding = "utf-8"
  end

  def parse dir
    root_element = create_element
    @xml.elements.add(root_element)
    File.write(@@results_path + dir + parse_file_name(@file_name) + ".xml", @xml)
  end

  def create_element
    root_element = super
    xml = REXML::Element.new("layout",nil,@xml.context)
    xml.attributes["xmlns:android"] = "http://schemas.android.com/apk/res/android"
    xml.attributes["xmlns:app"] = "http://schemas.android.com/apk/res/android"
    xml.attributes["xmlns:tools"] = "http://schemas.android.com/tools"
    xml.add(root_element)
    xml
  end

  def parse_json_to_xml json, parent_json
    puts "Error:" + @file_name if json.nil?
    view_type = get_view_type(json)
    children = (json["child"] || [])
    if view_type.nil?
      return get_include(json)
    end
    xml_view_type = MappingTable.view_types_map[view_type.to_sym] || "View"
    xml = REXML::Element.new(xml_view_type,nil,@xml.context)
    set_default_attributes(json, xml)
    json.each do |key,value|
      xml_key = MappingTable.attributes_map[key.to_sym]
      next if xml_key.nil?
      case key
      when "id"
        xml.attributes["android:" + xml_key] = "@+id/" + value
      when "style"
        xml.attributes[xml_key] = "@style/" + value.sub(/_style$/,"").to_camel
      when "width", "height"
        xml.attributes["android:" + xml_key] = get_size(value)
      when "weight"
        orientation = parent_json["orientation"]
        if orientation == "vertical"
          xml.attributes["android:layout_height"] = "0" + "dp"
        elsif orientation == "horizontal"
          xml.attributes["android:layout_width"] = "0" + "dp"
        end
        xml.attributes["android:" + xml_key] = parse_float_to_int_if_needed(value).to_s
      when "orientation"
        xml.attributes["android:" + xml_key] = value
      when "alignTopOfView","alignLeftOfView","alignBottomOfView","alignRightOfView","alignTopView","alignLeftView","alignBottomView","alignRightView"
        xml.attributes["android:" + xml_key] = "@+id/" + value
      when "alignTop","alignLeft","alignBottom","alignRight","centerVertical","centerHorizontal"
        if !parent_json["orientation"].nil?
          xml.attributes["android:layout_gravity"] = get_linear_gravity(json)
        else
          xml.attributes["android:" + xml_key] = value
        end
      when "text","hint"
        xml.attributes["android:" + xml_key] = "@string/" + value
      when "fontSize"
        xml.attributes["android:" + xml_key] = parse_float_to_int_if_needed(value).to_s + "dp"
      when "fontColor"
        xml.attributes["android:" + xml_key] = parse_color(value).to_s
      when "textAlign"
        xml.attributes["android:" + xml_key] = value.to_snake + "|center_vertical"
      when "input"
        hash_map = get_input_type_set(json, xml_key, value)
        xml.attributes[hash_map[:key]] = hash_map[:value]
      when "gravity"
        xml.attributes["android:" + xml_key] = value.map{|v| v.to_snake}.join("|")
      when "src"
        xml.attributes["android:" + xml_key] = "@drawable/" + value
      when "onclick"
        xml.attributes["android:" + xml_key] = value
      else
        xml.attributes["android:" + xml_key] = parse_float_to_int_if_needed(value).to_s + "dp"
      end
    end
    xml.attributes["android:background"]  = parse_drawable(json)
    children.each do |child|
      xml.elements.add(parse_json_to_xml(child, json))
    end
    xml
  end

  def get_view_type json
    view_type = json["type"]
    children = (json["child"] || [])
    if "View" == view_type 
      if !children.empty?
        view_type = json["orientation"] == nil ? "Relative" : "Linear"
      end
    end
    view_type
  end

  def get_include json
    xml_include =  json["include"]
    xml = REXML::Element.new("include")
    xml.attributes["layout"] = "@layout/" + xml_include
    return xml
  end

  def set_default_attributes json, xml
    view_type = get_view_type(json)
    style = get_style(json)
    if !style.nil?
      case view_type
      when "Label"
        xml.attributes["android:gravity"] = "center_vertical" if style.elements["item[@name='" + "android:gravity" + "']"].nil? 
      when "TextField"
        xml.attributes["android:inputType"] = "text" if style.elements["item[@name='" + "android:inputType" + "']"].nil? 
        xml.attributes["android:gravity"] = "center_vertical" if style.elements["item[@name='" + "android:gravity" + "']"].nil?
      when "Button"
        xml.attributes["android:gravity"] = "center" if style.elements["item[@name='" + "android:gravity" + "']"].nil?
      end
    else
      case view_type
      when "Label"
        xml.attributes["android:gravity"] = "center_vertical"
      when "TextField"
        xml.attributes["android:inputType"] = "text" if json["input"].nil?
        xml.attributes["android:gravity"] = "center_vertical"
      when "Button"
        xml.attributes["android:gravity"] = "center"
      end
    end
    fill_size_if_empty(xml, json, style)
  end

  def get_size value
    case value
    when "matchParent"
      return "match_parent"
    when "wrapContent"
      return "wrap_content"
    else
      return parse_float_to_int_if_needed(value).to_s + "dp"
    end
  end

  def get_linear_gravity json
    layout_gravities = []
    layout_gravities << "top" if (json["alignTop"] || false)
    layout_gravities << "left" if (json["alignLeft"] || false)
    layout_gravities << "bottom" if (json["alignBottom"] || false)
    layout_gravities << "right" if (json["alignRight"] || false)
    if (json["centerVertical"] || false) && (json["centerHorizontal"] || false)
      layout_gravities << "center"
    else
      layout_gravities << "center_vertical" if (json["centerVertical"] || false)
      layout_gravities << "center_horizontal" if (json["centerHorizontal"] || false)
    end
    layout_gravities.join("|")
  end

  def get_input_type_set json, xml_key, value
    hash_map = {}
    case value
    when "alphabet"
      hash_map[:key] = xml.attributes["android:digits"] 
      hash_map[:value] = "abcdefghijklmnopqrstuvwxyz1234567890 "
    when "email"
      hash_map[:key] = "android:" + xml_key
      hash_map[:value] = "textEmailAddress"
    when "password"
      hash_map[:key] = "android:" + xml_key
      hash_map[:value] = "textPassword"
    when "number"
      hash_map[:key] = "android:" + xml_key
      if (json["secure"] || false)
        hash_map[:value] = "numberPassword"
      else 
        hash_map[:value] = "number"
      end
    when "decimal"
      hash_map[:key] = "android:" + xml_key
      hash_map[:value] = "numberDecimal"
    end
    hash_map
  end

  def get_style json
    return nil if json["style"].nil?
    style_xml = REXML::Document.new(File.new(StyleParser.style_file_path), @xml.context)
    resources = style_xml.get_elements("resources")[0]
    style = resources.get_elements("style").select{|s| s.attributes["name"] == json["style"].sub(/_style$/,"").to_camel}[0]
    style
  end

  def fill_size_if_empty xml, json, style
    if json["type"] == "Label" || json["type"] == "Image"
      xml.attributes["android:layout_width"] = "wrap_content" if style.nil? || style.elements["item[@name='" + "android:layout_width" + "']"].nil?
      xml.attributes["android:layout_height"] = "wrap_content" if style.nil? || style.elements["item[@name='" + "android:layout_height" + "']"].nil?
    end
  end
end
