# frozen_string_literal: true

require "json"
require "time"
require "fileutils"
require_relative "string_module"
require_relative "xcode_project"
require_relative "view_binding_handler_factory"
require_relative "build_cache_manager"
require_relative "json_loader_config"
require_relative "binding_file_manager"
require_relative "import_module_manager"
require_relative "json_analyzer"
require_relative "ui_control_event_manager"
require_relative "../core/project_finder"
require_relative "../core/config_manager"

module SjuiTools
  module Binding
    class JsonLoader
      def initialize(project_root_path = nil, project_file_path = nil)
        # Setup project paths
        Core::ProjectFinder.setup_paths(project_file_path)
        
        @project_file_path = Core::ProjectFinder.project_file_path
        @project_dir = Core::ProjectFinder.project_dir
        
        # Get paths from config
        source_path = Core::ProjectFinder.get_full_source_path
        config = Core::ConfigManager.load_config
        
        @view_path = File.join(source_path, config['view_directory'])
        @layout_path = File.join(source_path, config['layouts_directory'])
        @style_path = File.join(source_path, config['styles_directory'])
        @binding_path = File.join(source_path, config['bindings_directory'])
        
        @new_binding_files = []
        @xcode_project_manager = XcodeProjectManager.new(@project_file_path) if @project_file_path
        @cache_manager = BuildCacheManager.new(@project_dir)
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
        json_updated_flag = false
        
        puts @layout_path
        
        # ディレクトリが存在しない場合は警告を表示して終了
        unless Dir.exist?(@layout_path)
          puts "Warning: Layouts directory not found: #{@layout_path}"
          puts "Please run 'sjui init' first to create the directory structure."
          return
        end
        
        Dir.glob("#{@layout_path}/**/*.json") do |file|
          next if File.basename(file).start_with?("_")
          
          # キャッシュチェック
          unless @cache_manager.needs_update?(file, last_updated, @layout_path, last_including_files)
            puts "Skip: #{file} (not updated)"
            next
          end
          
          puts "Processing: #{file}"
          json_updated_flag = true
          
          # インポートマネージャーとUIコントロールイベントマネージャーをリセット
          @import_module_manager.reset
          @ui_control_event_manager.reset
          
          # ファイル情報のセットアップ
          file_name = File.basename(file, ".*")
          binding_info = @binding_file_manager.setup_binding_file_info(file_name)
          
          # JSONアナライザーの初期化
          @json_analyzer = JsonAnalyzer.new(
            @import_module_manager,
            @ui_control_event_manager,
            @layout_path,
            @style_path,
            binding_info[:super_binding],
            @@view_type_set
          )
          
          # JSONファイルの読み込みと解析
          File.open(file, "r") do |f|
            json_string = f.read
            json = JSON.parse(json_string)
            @json_analyzer.analyze_json(file_name, json)
          end
          
          # Bindingファイルの生成
          generate_binding_file(binding_info)
        end
        
        # XcodeProjectManagerが存在する場合は、新しいバインディングファイルを追加
        if @xcode_project_manager && @new_binding_files.size > 0
          puts "Adding binding files to Xcode project..."
          @xcode_project_manager.add_binding_files(@new_binding_files, @project_dir)
        end
        
        # キャッシュの保存
        @cache_manager.save_cache(@json_analyzer.including_files) if json_updated_flag
        
        puts "Build completed successfully!"
      end

      private

      def generate_binding_file(binding_info)
        # インポート文の生成
        import_content = @import_module_manager.generate_import_statements
        
        # bindingクラスのヘッダー生成
        header_content = generate_class_header(binding_info)
        
        # data変数の生成
        data_content = generate_data_variables
        
        # weak変数宣言
        weak_vars_content = @json_analyzer.weak_vars_content
        
        # bindViewメソッドの生成
        bind_view_content = @ui_control_event_manager.generate_bind_view_method
        
        # invalidateメソッドの生成
        @json_analyzer.generate_invalidate_methods
        invalidate_content = @json_analyzer.invalidate_methods_content
        
        # 全体のコンテンツ生成
        full_content = import_content + "\n" +
                      header_content +
                      data_content +
                      weak_vars_content + "\n" +
                      bind_view_content +
                      invalidate_content +
                      "}\n"
        
        # ファイルに書き込み
        File.open(binding_info[:binding_file_path], "w") do |file|
          file.write(full_content)
        end
        
        @new_binding_files << binding_info[:binding_file_path]
        puts "Generated: #{binding_info[:binding_file_name]}"
      end

      def generate_class_header(binding_info)
        <<~SWIFT
        class #{binding_info[:binding_class_name]}: #{binding_info[:super_binding]} {
            weak var viewHolder: UIViewController!
            var isInitialized = false
            
            override init(viewHolder: UIViewController) {
                super.init(viewHolder: viewHolder)
                self.viewHolder = viewHolder
            }
            
        SWIFT
      end

      def generate_data_variables
        return "" if @json_analyzer.data_sets.empty?
        
        content = "    // MARK: - Data Variables\n"
        @json_analyzer.data_sets.each do |data|
          next if JsonLoaderConfig::IGNORE_DATA_SET[data.to_sym]
          variable_name = data.camelize
          variable_name[0] = variable_name[0].chr.downcase
          content << "    weak var #{variable_name}: NSObject!\n"
        end
        content << "\n"
        content
      end
    end
  end
end