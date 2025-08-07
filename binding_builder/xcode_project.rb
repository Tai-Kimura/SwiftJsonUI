# Xcode Project Management Modules
# 
# このファイルをrequireすることで、Xcodeプロジェクト管理に
# 必要なすべてのモジュールとクラスが利用可能になります。
#
# Usage:
#   require_relative "xcode_project"
#   
#   # Xcode project management
#   manager = XcodeProjectManager.new("path/to/project.pbxproj")
#   manager.add_binding_files(["SampleBinding.swift"])
#   manager.add_view_controller_file("SampleViewController.swift", "Sample", "sample.json")
#   
#   # View generation
#   generator = ViewGenerator.new
#   generator.generate("sample")

require_relative "project_finder"
require_relative "xcode_project/adders/binding_files_adder"
require_relative "xcode_project/adders/view_controller_adder"
require_relative "xcode_project/xcode_project_manager"
require_relative "xcode_project/generators/view_generator"