require File.expand_path(File.dirname(__FILE__)) + "/json_loader"
require File.expand_path(File.dirname(__FILE__)) + "/import_module_manager"
require File.expand_path(File.dirname(__FILE__)) + "/project_finder"

# View typeの拡張
JsonLoader.view_type_set.merge!({"Map": "GMSMapView"})
ImportModuleManager.add_type_import_mapping("Map", "GoogleMaps")

begin
  # プロジェクトファイルを検索
  project_file_path = ProjectFinder.find_project_file(File.dirname(__FILE__))
  json_loader = JsonLoader.new(nil, project_file_path)
  json_loader.start_analyze
rescue => e
  puts "Error: #{e.message}"
  puts "Falling back to legacy mode..."
  # フォールバック：従来の方式
  json_loader = JsonLoader.new("../")
  json_loader.start_analyze
end