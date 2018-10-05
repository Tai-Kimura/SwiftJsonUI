require 'json'
require 'rexml/document'
require './mapping_table'
require './string_module'
class Parser
  @@root_path = "../hot_loader/public/cocoapodtest/"
  @@results_path = "results/"

  def self.root_path
    @@root_path
  end

  def self.results_path
    @@results_path
  end

  def initialize file
    begin
      @file_name = file.split("/")[-1].sub!(/\.json$/, "")
      @json = open(file) do |io|
        JSON.load(io)
      end
      @xml = REXML::Document.new("XML")
      @xml.context[:attribute_quote] = :quote
    rescue => ex
      puts @file_name
      puts ex.message
    end
  end

  def create_element
    parse_json_to_xml(@json, nil)
  end

  def parse_json_to_xml json, parent_json
    raise "Called abstract method: parse_json_to_xml"
  end

  def parse_float_to_int_if_needed float_value
    return "" unless float_value.is_a?(Float) || float_value.is_a?(Integer)
    value = float_value
    if float_value - float_value.to_i.to_f == 0
      value = float_value.to_i
    end
    value
  end

  def parse_drawable json
    background = json["background"]
    corner_radius = json["cornerRadius"]
    border_color = json["borderColor"]
    border_width = json["borderWidth"]
    return parse_color(background) if corner_radius.nil? && (border_color.nil? || border_width.nil?)
    return parse_onclick(json) || parse_background(json) 
  end

  def parse_background json
    xml = REXML::Document.new("XML")
    xml.context[:attribute_quote] = :quote
    xml_decl = xml.xml_decl
    xml_decl.version = 1.0
    xml_decl.encoding = "utf-8"
    selector = REXML::Element.new("selector",xml,@xml.context)
    selector.attributes["xmlns:android"] = "http://schemas.android.com/apk/res/android"
    item = REXML::Element.new("item",selector,@xml.context)
    shape = REXML::Element.new("shape",item,@xml.context)
    shape.attributes["android:shape"] = "rectangle"
    parse_rect(json, shape)
    file_name = duplicated_file(xml)
    if file_name.nil?
      file_name = json["id"].nil? ? @file_name + "_" + Time.now.to_i.to_s + "_background" : json["id"] + "_background"
      File.write(drawable_dir + "/" + file_name + ".xml", xml)
    end
    return "@drawable/" + file_name
  end

  def parse_onclick json
    return nil if json["onclick"].nil? && json["events"].nil?
    xml = REXML::Document.new("XML")
    xml.context[:attribute_quote] = :quote
    xml_decl = xml.xml_decl
    xml_decl.version = 1.0
    xml_decl.encoding = "utf-8"
    ripple = REXML::Element.new("ripple",xml,@xml.context)
    ripple.attributes["xmlns:android"] = "http://schemas.android.com/apk/res/android"
    ripple.attributes["android:color"] = "?android:colorControlHighlight"
    item = REXML::Element.new("item",ripple,@xml.context)
    shape = REXML::Element.new("shape",item,@xml.context)
    parse_rect(json, shape)
    file_name = duplicated_file(xml)
    if file_name.nil?
      file_name = json["id"].nil? ? @file_name + "_" + Time.now.to_i.to_s + "_background" : json["id"] + "_background"
      File.write(drawable_dir + "/" + file_name + ".xml", xml)
    end
    return "@drawable/" + file_name
  end

  def parse_rect json, shape
    background = json["background"]
    corner_radius = json["cornerRadius"]
    border_color = json["borderColor"]
    border_width = json["borderWidth"]
    if !background.nil?
      solid = REXML::Element.new("solid",shape,@xml.context)
      solid.attributes["android:color"] = parse_color(background)
    end
    if !corner_radius.nil?
      corners = REXML::Element.new("corners",shape,@xml.context)
      corners_to_curve = ["topLeftRadius","topRightRadius","bottomLeftRadius","bottomRightRadius"]
      margin_top = json["topMargin"] || 0
      margin_left = json["leftMargin"] || 0
      margin_bottom = json["bottomMargin"] || 0
      margin_right = json["rightMargin"] || 0
      if margin_top < 0 
        corners_to_curve.delete "topLeftRadius"
        corners_to_curve.delete "topRightRadius"
      end
      if margin_left < 0 
        corners_to_curve.delete "topLeftRadius"
        corners_to_curve.delete "bottomLeftRadius"
      end
      if margin_bottom < 0 
        corners_to_curve.delete "bottomLeftRadius"
        corners_to_curve.delete "bottomRightRadius"
      end
      if margin_right < 0 
        corners_to_curve.delete "topRightRadius"
        corners_to_curve.delete "bottomRightRadius"
      end
      corners_to_curve.each do |c|
        corners.attributes["android:" + c] = parse_float_to_int_if_needed(corner_radius).to_s + "dp"
      end
    end
    if !border_width.nil? && !border_color.nil?
      stroke = REXML::Element.new("stroke",shape,@xml.context)
      stroke.attributes["android:color"] = parse_color(border_color)
      stroke.attributes["android:width"] = parse_float_to_int_if_needed(border_width).to_s + "dp"
    end
  end

  def duplicated_file xml
    file_name = nil
    xml_str = xml.to_s
    files = Dir[drawable_dir + "/*.xml"]
    files.each do |file|
      doc = REXML::Document.new(File.new(file), @xml.context).to_s
      if doc == xml_str
        file_name = file.split("/")[-1].sub(/\.xml/, "") and break 
      end
    end
    file_name
  end

  def drawable_dir
    dirname = @@results_path + "drawable"
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
    dirname
  end

  def parse_color color_value
    if color_value.is_a? Integer
      color_name = ""
      case color_value
      when 0
        color_name = "app_black"
      when 1
        color_name = "app_white"
      when 2
        color_name = "app_orange"
      when 3
        color_name = "app_light_clear_orange"
      when 4
        color_name = "app_blue"
      when 5
        color_name = "app_clear_orange"
      when 6
        color_name = "app_trans_black"
      when 7
        color_name = "app_light_midium_gray"
      when 8
        color_name = "app_midium_gray"
      when 9
        color_name = "base_text_color"
      when 10
        color_name = "light_text_color"
      when 11
        color_name = "credit_danger_color"
      when 12
        color_name = "credit_warned_color"
      when 13
        color_name = "app_line_gray"
      when 14
        color_name = "app_black"
      when 15
        color_name = "app_black"
      when 16
        color_name = "app_black"
      when 17
        color_name = "app_black"
      when 18
        color_name = "app_light_gray"
      when 19
        color_name = "app_black"
      when 20
        color_name = "app_black"
      when 21
        color_name = "app_lighter_gray"
      when 22
        color_name = "app_midium_gray"
      when 23
        color_name = "app_orange_second"
      when 24
        color_name = "app_orange_third"
      when 25
        color_name = "hint_text_color"
      when 26
        color_name = "app_red"
      when 27
        color_name = "link_color"
      when 28
        color_name = "app_black"
      when 29
        color_name = "app_gray_white"
      when 30
        color_name = "app_extra_white"
      when 99
        color_name = "app_clear"
      end
      "@color/" + color_name
    else
      color_value
    end
  end

  def parse_file_name file_name
    xml_file_name = file_name
    if file_name.match(/_cell$/)
      xml_file_name = "list_item_" + (file_name.sub(/_cell$/,"")) 
    elsif file_name.match(/_header$/) || file_name.match(/_footer$/)
      xml_file_name = "list_item_" + file_name
    else
      xml_file_name = "activity_" + file_name
    end
    xml_file_name
  end
end
