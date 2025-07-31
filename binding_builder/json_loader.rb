require "json"
require "time"
require "fileutils"
require File.expand_path(File.dirname(__FILE__)) + "/string_module"
require File.expand_path(File.dirname(__FILE__)) + "/xcode_project"
require File.expand_path(File.dirname(__FILE__)) + "/view_binding_handler_factory"
require File.expand_path(File.dirname(__FILE__)) + "/build_cache_manager"
require File.expand_path(File.dirname(__FILE__)) + "/json_loader_config"
require File.expand_path(File.dirname(__FILE__)) + "/binding_file_manager"
require File.expand_path(File.dirname(__FILE__)) + "/import_module_manager"
require File.expand_path(File.dirname(__FILE__)) + "/json_analyzer"
require File.expand_path(File.dirname(__FILE__)) + "/ui_control_event_manager"
require File.expand_path(File.dirname(__FILE__)) + "/project_finder"
require File.expand_path(File.dirname(__FILE__)) + "/config_manager"

class JsonLoader


  def initialize(project_root_path = nil, project_file_path = nil)
    base_dir = File.dirname(__FILE__)
    
    # ProjectFinderを使用してプロジェクトファイルパスを設定
    @project_file_path = project_file_path || ProjectFinder.setup_project_file(base_dir)
    
    # ProjectFinderを使用してパスを設定（project_file_pathを渡す）
    paths = ProjectFinder.setup_paths(base_dir, @project_file_path)
    @view_path = paths.view_path
    @layout_path = paths.layout_path
    @style_path = paths.style_path
    @binding_path = paths.bindings_path
    
    @new_binding_files = []
    @xcode_project_manager = XcodeProjectManager.new(@project_file_path) if @project_file_path
    @cache_manager = BuildCacheManager.new(File.dirname(__FILE__))
    @binding_file_manager = BindingFileManager.new(@view_path, @binding_path)
    @import_module_manager = ImportModuleManager.new
    @ui_control_event_manager = UIControlEventManager.new
    @json_analyzer = JsonAnalyzer.new(@import_module_manager, @ui_control_event_manager, @layout_path, @style_path, nil, @@view_type_set)
    @including_files = {}
  end

  @@view_type_set = JsonLoaderConfig::VIEW_TYPE_SET.dup

  def self.view_type_set
    @@view_type_set
  end

  def start_analyze
    last_updated = @cache_manager.load_last_updated
    last_including_files = @cache_manager.load_last_including_files
    puts "last_updated: #{last_updated}"
    Dir.glob("#{@layout_path}/*.json") do |file_path|
      puts file_path
      file_name = File.basename(file_path, ".*")
      
      # キャッシュマネージャーを使用して更新が必要かチェック
      unless @cache_manager.needs_update?(file_path, last_updated, @layout_path, last_including_files)
        next
      end
      next if file_name.start_with?("_")
      puts "Update Binding"
      
      # マネージャーをリセット
      @import_module_manager.reset
      @ui_control_event_manager.reset
      
      @binding_file_manager.setup_binding_file_info(file_name)
      
      # JsonAnalyzerを再初期化してsuper_bindingを設定
      @json_analyzer = JsonAnalyzer.new(@import_module_manager, @ui_control_event_manager, @layout_path, @style_path, @binding_file_manager.super_binding, @@view_type_set)
      
      File.open(file_path) do |file|
        json = JSON.load(file)
        @json_analyzer.analyze_json(file_name, json)
      end
      import_module_content = @import_module_manager.generate_import_statements
      data_content = ""
      # データセットを初期化（isInitialized）
      data_sets = [JSON.parse({"name": "isInitialized", "class": "Bool", "defaultValue": "true"}.to_json)] + @json_analyzer.data_sets
      
      data_sets.each do |data|
        next if @binding_file_manager.super_binding != "Binding" && !JsonLoaderConfig::IGNORE_DATA_SET[data["name"].to_sym].nil?
        modifier = data["modifier"].nil? ? "var" : data["modifier"]
        if data["defaultValue"].nil?
          data_content << "    #{modifier} #{data["name"]}: #{data["class"]}?\n"
        else
          data_content << "    #{modifier} #{data["name"]}: #{data["class"]}#{data["optional"] ? "?" : ""} = #{data["defaultValue"].to_s.gsub(/'/, "\"")}\n"
        end
      end
      binding_content = "#{import_module_content}\n@MainActor\nclass #{@binding_file_manager.binding_class_name}: #{@binding_file_manager.super_binding} {\n" + data_content + @json_analyzer.weak_vars_content
      binding_content << @ui_control_event_manager.generate_bind_view_method
      
      # JsonAnalyzerでinvalidateメソッドを生成
      @json_analyzer.generate_invalidate_methods
      binding_content << @json_analyzer.invalidate_methods_content
      
      binding_content << "}"
      File.open(@binding_file_manager.binding_file_path, "w") do |binding_file|
        binding_file.write(binding_content)
      end
      @new_binding_files << @binding_file_manager.binding_file_name
      
      # including_filesを蓄積
      @json_analyzer.including_files.each do |file_name, includes|
        @including_files[file_name] = includes
      end
    end
    
    # バッチでXcodeプロジェクトに追加
    unless ENV['SRCROOT']
      puts "=== JsonLoader: Adding binding files to Xcode project ==="
      puts "SRCROOT: #{ENV['SRCROOT'].inspect}"
      puts "New binding files: #{@new_binding_files.inspect}"
      if @new_binding_files.any?
        puts "Calling add_binding_files..."
        @xcode_project_manager.add_binding_files(@new_binding_files)
      else
        puts "No new binding files to add"
      end
    else
      puts "=== JsonLoader: SRCROOT is set, skipping Xcode project update ==="
    end
    
    # キャッシュを保存
    @cache_manager.save_cache(@including_files)
  end

end