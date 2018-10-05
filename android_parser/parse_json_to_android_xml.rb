require './layout_parser'
require './style_parser'
require 'fileutils'
StyleParser.parse_all
LayoutParser.parse_all