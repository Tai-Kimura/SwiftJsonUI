require './parser'
class StyleParser < Parser

  def self.style_file_path
    dirname = Parser.results_path + "values/styles/styles.xml"
  end

  def self.parse_all
    value_dir = "values"
    style_dir = "values/styles"
    dirname = Parser.results_path + value_dir
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
    dirname = Parser.results_path + style_dir
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
    root_xml = REXML::Element.new("resources")
    files = Dir[Parser.root_path + "styles/*.json"]
    files.each do |file|
      parser = StyleParser.new(file)
      root_xml.add(parser.create_element)
    end
    File.write(dirname + "/styles.xml", root_xml)
  end

  def parse_json_to_xml json, parent_json
    puts "エラー:" + @file_name if json.nil?
    view_type = json["type"]
    xml = REXML::Element.new("style",nil,@xml.context)
    xml.attributes["name"] = @file_name.sub(/_style$/,"").to_camel
    json.each do |key,value|
      xml_key = MappingTable.attributes_map[key.to_sym]
      next if xml_key.nil?
      item = REXML::Element.new("item",xml,@xml.context)
      item.attributes["name"] = item_name(json,xml_key,key,value)
      item.text = item_text(json,key,value)
    end
    if !json["background"].nil? || !json["cornerRadius"].nil? || (!json["borderColor"].nil? && !json["borderWidth"].nil?)
      item = REXML::Element.new("item",xml,@xml.context)
      item.attributes["name"] = "android:background"
      item.text  = parse_drawable(json)
    end
    xml
  end

  def item_name json, xml_key, key, value
    case key
    when "input"
      case value
      when "alphabet"
        return "android:digits"
      else
        return "android:" + xml_key
      end
    when "alignTop","alignLeft","alignBottom","alignRight","centerVertical","centerHorizontal"
      return "android:layout_gravity"
    else
      return "android:" + xml_key
    end
  end

  def item_text json, key, value
    case key
    when "width", "height"
      case value
      when "matchParent"
        return "match_parent"
      when "wrapContent"
        return "wrap_content"
      else
        return parse_float_to_int_if_needed(value).to_s + "dp"
      end
    when "text","hint"
      return "@string/" + value
    when "fontSize"
      return parse_float_to_int_if_needed(value).to_s + "dp"
    when "fontColor"
      return parse_color(value).to_s
    when "textAlign"
      return value.to_snake + "|center_vertical"
    when "input"
      case value
      when "alphabet"
        return "abcdefghijklmnopqrstuvwxyz1234567890 "
      when "email"
        return "textEmailAddress"
      when "password"
        return "textPassword"
      when "number"
        if (json["secure"] || false)
          return "numberPassword"
        else 
          return "number"
        end
      when "decimal"
        return "numberDecimal"
      end
    when "alignTop","alignLeft","alignBottom","alignRight","centerVertical","centerHorizontal"
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
      return layout_gravities.join("|")
    else
      return parse_float_to_int_if_needed(value).to_s + "dp"
    end
  end
end
