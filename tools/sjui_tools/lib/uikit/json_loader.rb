# frozen_string_literal: true

require "json"
require "time"
require "fileutils"
require_relative "string_module"
require_relative "../core/xcode_project_manager"
require_relative "view_binding_handler_factory"
require_relative "build_cache_manager"
require_relative "json_loader_config"
require_relative "binding_file_manager"
require_relative "import_module_manager"
require_relative "json_analyzer"
require_relative "ui_control_event_manager"
require_relative "../core/project_finder"
require_relative "../core/config_manager"
require_relative "../core/logger"

module SjuiTools
  module UIKit
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
        @xcode_project_manager = Core::XcodeProjectManager.new(@project_file_path) if @project_file_path
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
        # Load ignore sets from config
        JsonLoaderConfig.load_ignore_sets_from_config
        
        last_updated = @cache_manager.load_last_updated
        last_including_files = @cache_manager.load_last_including_files
        json_updated_flag = false
        
        # 全ファイルのincluding_filesを集約するためのハッシュ
        all_including_files = {}
        
        Core::Logger.debug "Layout path: #{@layout_path}"
        
        # ディレクトリが存在しない場合は警告を表示して終了
        unless Dir.exist?(@layout_path)
          Core::Logger.error "Layouts directory not found: #{@layout_path}"
          Core::Logger.error "Please run 'sjui init' first to create the directory structure."
          return
        end
        
        Dir.glob("#{@layout_path}/**/*.json") do |file|
          # Skip Resources folder
          next if file.include?("#{@layout_path}/Resources/")
          
          # Partial files (starting with _) are now processed too
          # next if File.basename(file).start_with?("_")
          
          # キャッシュチェック
          unless @cache_manager.needs_update?(file, last_updated, @layout_path, last_including_files)
            Core::Logger.debug "Skip: #{file} (not updated)"
            next
          end
          
          Core::Logger.info "Processing: #{file}"
          json_updated_flag = true
          
          # インポートマネージャーとUIコントロールイベントマネージャーをリセット
          @import_module_manager.reset
          @ui_control_event_manager.reset
          
          # ファイル情報のセットアップ
          file_name = File.basename(file, ".*")
          binding_info = @binding_file_manager.setup_binding_file_info(file_name)
          
          # JSONアナライザーの初期化（各ファイルごとに新しいID登録で開始）
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
          begin
            generate_binding_file(binding_info)
            # Success - cleanup backup
            @binding_file_manager.cleanup_backup(binding_info[:backup_file_path])
            
            # このファイルのincluding_filesを全体のハッシュにマージ
            # 各ファイルのincluding情報を追加（上書きではなく追加）
            @json_analyzer.including_files.each do |key, values|
              all_including_files[key] ||= []
              all_including_files[key].concat(values)
              all_including_files[key].uniq!
            end
          rescue => e
            Core::Logger.error "Error generating binding file for #{file_name}: #{e.message}"
            Core::Logger.debug e.backtrace.first(5).join("\n")
            # Restore backup if generation failed
            @binding_file_manager.restore_backup(binding_info[:backup_file_path], binding_info[:binding_file_path])
            # Continue with next file instead of stopping completely
          end
        end
        
        # XcodeProjectManagerが存在する場合は、新しいバインディングファイルを追加
        if @xcode_project_manager && @new_binding_files.size > 0
          Core::Logger.info "Adding binding files to Xcode project..."
          @xcode_project_manager.add_binding_files(@new_binding_files, @project_dir)
        end
        
        # キャッシュの保存（集約された全ファイルのincluding_filesを保存）
        @cache_manager.save_cache(all_including_files) if json_updated_flag
        
        Core::Logger.success "Build completed successfully!"
      end

      private

      def generate_initializer
        has_partials = !@json_analyzer.partial_bindings.empty?
        
        content = String.new("\n")
        
        # Add convenience init without bindingId
        content << "    required convenience init(viewHolder: ViewHolder) {\n"
        content << "        self.init(viewHolder: viewHolder, bindingId: nil)\n"
        content << "    }\n"
        content << "\n"
        
        # Main initializer with bindingId parameter
        content << "    required public init(viewHolder: ViewHolder, bindingId: String? = nil) {\n"
        content << "        self.bindingId = bindingId\n"
        
        if has_partials
          content << "        super.init(viewHolder: viewHolder)\n"
          
          # Initialize partial bindings
          @json_analyzer.partial_bindings.each do |partial|
            if partial[:binding_id]
              content << "        self.#{partial[:property_name]}Binding = #{partial[:binding_class]}(viewHolder: viewHolder, bindingId: \"#{partial[:binding_id]}\")\n"
            else
              content << "        self.#{partial[:property_name]}Binding = #{partial[:binding_class]}(viewHolder: viewHolder)\n"
            end
          end
          
          # Set default values for shared_data in partial bindings
          @json_analyzer.partial_bindings.each do |partial|
            if partial[:shared_data_bindings]
              partial[:shared_data_bindings].each do |key, value|
                # shared_data values can be either simple property names or binding expressions
                if value.is_a?(String)
                  binding_var = if value.start_with?("@{")
                    value.sub(/^@\{/, "").sub(/\}$/, "")
                  else
                    value
                  end
                  
                  # Check if this data has a default value
                  data_with_default = @json_analyzer.data_sets.find do |data|
                    if data.is_a?(Hash)
                      data["name"] == binding_var && data.has_key?("defaultValue")
                    elsif data.is_a?(String)
                      # Simple string format doesn't have explicit default, but String defaults to ""
                      data == binding_var
                    end
                  end
                  
                  if data_with_default
                    if data_with_default.is_a?(Hash) && data_with_default.has_key?("defaultValue")
                      default_value = data_with_default["defaultValue"]
                      if data_with_default["class"] == "String"
                        # Handle string default values
                        value_str = default_value.to_s
                        if value_str == "''"
                          default_value = '""'
                        elsif value_str.start_with?("'") && value_str.end_with?("'") && value_str.length > 1
                          inner_content = value_str[1...-1]
                          escaped_content = inner_content.gsub('\\', '\\\\').gsub('"', '\\"')
                          default_value = "\"#{escaped_content}\""
                        elsif !value_str.start_with?('"') || !value_str.end_with?('"')
                          escaped_content = value_str.gsub('\\', '\\\\').gsub('"', '\\"')
                          default_value = "\"#{escaped_content}\""
                        else
                          default_value = value_str
                        end
                      elsif data_with_default["class"] == "Bool"
                        default_value = default_value.to_s.downcase
                      else
                        default_value = default_value.to_s
                      end
                      content << "        self.#{partial[:property_name]}Binding.#{key} = #{default_value}\n"
                    elsif data_with_default.is_a?(String)
                      # Simple string defaults to empty string
                      content << "        self.#{partial[:property_name]}Binding.#{key} = \"\"\n"
                    end
                  end
                end
              end
            end
          end
        else
          content << "        super.init(viewHolder: viewHolder)\n"
        end
        
        content << "    }\n"
        content
      end

      def generate_partial_binding_properties
        return "" if @json_analyzer.partial_bindings.empty?
        
        content = String.new
        @json_analyzer.partial_bindings.each do |partial|
          content << "    private(set) var #{partial[:property_name]}Binding: #{partial[:binding_class]}!\n"
        end
        content << String.new("\n") unless content.empty?
        content
      end

      def generate_bind_view_with_partials
        # Get the base bindView content from UI control event manager
        base_content = @ui_control_event_manager.generate_bind_view_method
        
        # Check if we need to generate bindView
        needs_bind_view = !@json_analyzer.partial_bindings.empty? || !@json_analyzer.view_variables.empty?
        
        # If there's nothing to add, return the base content
        return base_content unless needs_bind_view
        
        # If there's already a bindView method, we need to add to it
        if base_content.empty?
          # No existing bindView, create one with view assignments and partial bindings
          content = String.new("\n")
          content << "    override func bindView() {\n"
          content << "        super.bindView()\n"
          
          # Add view assignments from weak vars
          unless @json_analyzer.view_variables.empty?
            content << "        \n"
            content << "        // Assign views from ViewHolder\n"
            @json_analyzer.view_variables.each do |view_var|
              content << "        #{view_var[:variable_name]} = getView(\"#{view_var[:original_id]}\", bindingId: bindingId)\n"
            end
            content << "        \n"
          end
          
          # Add partial binding calls
          @json_analyzer.partial_bindings.each do |partial|
            content << "        #{partial[:property_name]}Binding.bindView()\n"
          end
          
          content << "    }\n"
          content
        else
          # Insert partial binding calls into existing bindView
          # Find the position after super.bindView()
          insert_pos = base_content.index("super.bindView()\n")
          if insert_pos
            insert_pos += "super.bindView()\n".length
            
            partial_calls = String.new
            @json_analyzer.partial_bindings.each do |partial|
              partial_calls << "        #{partial[:property_name]}Binding.bindView()\n"
            end
            
            # Make a mutable copy of base_content before inserting
            base_content = base_content.dup
            base_content.insert(insert_pos, partial_calls)
          end
          base_content
        end
      end

      def generate_binding_file(binding_info)
        # インポート文の生成
        import_content = @import_module_manager.generate_import_statements
        
        # bindingクラスのヘッダー生成
        header_content = generate_class_header(binding_info)
        
        # data変数の生成
        data_content = generate_data_variables(binding_info)
        
        # weak変数宣言
        weak_vars_content = @json_analyzer.weak_vars_content
        
        # partial binding変数の生成
        partial_binding_content = generate_partial_binding_properties
        
        # initializerの生成
        initializer_content = generate_initializer
        
        # bindViewメソッドの生成（partial bindingsを含む）
        bind_view_content = generate_bind_view_with_partials
        
        # invalidateメソッドの生成
        @json_analyzer.generate_invalidate_methods
        invalidate_content = @json_analyzer.invalidate_methods_content
        
        # 全体のコンテンツ生成
        full_content = import_content + "\n" +
                      header_content +
                      data_content +
                      weak_vars_content + "\n" +
                      partial_binding_content +
                      initializer_content +
                      bind_view_content +
                      invalidate_content +
                      "}\n"
        
        # Debug: Check if the content already has an initializer
        if full_content.include?("override init(viewHolder: BaseViewController)")
          Core::Logger.warn "Found override init in generated content!"
        end
        
        # ファイルに書き込み
        File.open(binding_info[:binding_file_path], "w") do |file|
          file.write(full_content)
        end
        
        @new_binding_files << binding_info[:binding_file_path]
        Core::Logger.success "Generated: #{binding_info[:binding_file_name]}"
      end

      def generate_class_header(binding_info)
        <<~SWIFT
        @MainActor
        class #{binding_info[:binding_class_name]}: #{binding_info[:super_binding]} {
            var isInitialized = false
            private let bindingId: String?
            
        SWIFT
      end

      def generate_data_variables(binding_info)
        return "" if @json_analyzer.data_sets.empty?
        
        content = String.new
        @json_analyzer.data_sets.each do |data|
          # Handle both string and object formats
          if data.is_a?(String)
            # Simple string format - default to String type with empty default value
            next if JsonLoaderConfig::IGNORE_DATA_SET[data.to_sym]
            modifier = "var"
            
            # Check if this data is passed to any child partials
            has_child_bindings = check_data_passed_to_partials(data)
            
            if has_child_bindings
              content << "    #{modifier} #{data}: String = \"\" {\n"
              content << "        didSet {\n"
              content << generate_didset_content_for_data(data)
              content << "        }\n"
              content << "    }\n"
            else
              content << "    #{modifier} #{data}: String = \"\"\n"
            end
          else
            # Object format with name, class, defaultValue, etc.
            next if binding_info[:super_binding] != "Binding" && JsonLoaderConfig::IGNORE_DATA_SET[data["name"].to_sym]
            modifier = data["modifier"].nil? ? "var" : data["modifier"]
            data_name = data["name"]
            
            # Check if this data is passed to any child partials
            has_child_bindings = check_data_passed_to_partials(data_name)
            
            if data["defaultValue"].nil?
              if has_child_bindings
                content << "    #{modifier} #{data_name}: #{data["class"]}? {\n"
                content << "        didSet {\n"
                content << generate_didset_content_for_data(data_name)
                content << "        }\n"
                content << "    }\n"
              else
                content << "    #{modifier} #{data_name}: #{data["class"]}?\n"
              end
            else
              if data["class"] == "String"
                # For string values, handle various quote patterns
                value_str = data["defaultValue"].to_s
                
                # Handle different quote patterns
                if value_str == "''"
                  # Empty string with single quotes
                  default_value = '""'
                elsif value_str.start_with?("'") && value_str.end_with?("'") && value_str.length > 1
                  # String wrapped in single quotes - remove outer quotes and use inner content
                  inner_content = value_str[1...-1]
                  # Escape any backslashes and double quotes for Swift string literal
                  escaped_content = inner_content.gsub('\\', '\\\\').gsub('"', '\\"')
                  default_value = "\"#{escaped_content}\""
                elsif value_str.start_with?('"') && value_str.end_with?('"')
                  # Already a complete Swift string literal - use as is
                  default_value = value_str
                else
                  # No quotes or other pattern - wrap in double quotes and escape
                  escaped_content = value_str.gsub('\\', '\\\\').gsub('"', '\\"')
                  default_value = "\"#{escaped_content}\""
                end
              elsif data["class"] == "Bool"
                default_value = data["defaultValue"].to_s.downcase
              else
                default_value = data["defaultValue"].to_s
              end
              
              if has_child_bindings
                content << "    #{modifier} #{data_name}: #{data["class"]}#{data["optional"] ? "?" : ""} = #{default_value} {\n"
                content << "        didSet {\n"
                content << generate_didset_content_for_data(data_name)
                content << "        }\n"
                content << "    }\n"
              else
                content << "    #{modifier} #{data_name}: #{data["class"]}#{data["optional"] ? "?" : ""} = #{default_value}\n"
              end
            end
          end
        end
        content << String.new("\n") unless content.empty?
        content
      end
      
      def check_data_passed_to_partials(data_name)
        @json_analyzer.partial_bindings.any? do |partial|
          partial[:shared_data_bindings] && 
          partial[:shared_data_bindings].any? do |key, value|
            # shared_data values can be either simple property names (e.g., "review": "review")
            # or binding expressions (e.g., "review": "@{review}")
            if value.is_a?(String)
              if value.start_with?("@{")
                binding_var = value.sub(/^@\{/, "").sub(/\}$/, "")
                binding_var == data_name
              else
                value == data_name
              end
            else
              false
            end
          end
        end
      end
      
      def generate_didset_content_for_data(data_name)
        content = String.new
        @json_analyzer.partial_bindings.each do |partial|
          if partial[:shared_data_bindings]
            partial[:shared_data_bindings].each do |key, value|
              # shared_data values can be either simple property names (e.g., "review": "review")
              # or binding expressions (e.g., "review": "@{review}")
              if value.is_a?(String)
                binding_var = if value.start_with?("@{")
                  value.sub(/^@\{/, "").sub(/\}$/, "")
                else
                  value
                end
                if binding_var == data_name
                  content << "            #{partial[:property_name]}Binding?.#{key} = #{data_name}\n"
                end
              end
            end
          end
        end
        content
      end
    end
  end
end