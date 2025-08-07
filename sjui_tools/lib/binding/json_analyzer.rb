# frozen_string_literal: true

require 'set'
require_relative 'json_loader_config'
require_relative 'view_binding_handler_factory'
require_relative 'string_module'

module SjuiTools
  module Binding
    class JsonAnalyzer
      attr_reader :binding_content, :data_sets, :binding_processes_group, :including_files, :reset_constraint_views, :weak_vars_content, :invalidate_methods_content, :partial_bindings

      def initialize(import_module_manager, ui_control_event_manager, layout_path, style_path, super_binding, view_type_set)
        @import_module_manager = import_module_manager
        @ui_control_event_manager = ui_control_event_manager
        @layout_path = layout_path
        @style_path = style_path
        @super_binding = super_binding
        @view_type_set = view_type_set
        @binding_content = String.new
        @weak_vars_content = String.new
        @invalidate_methods_content = String.new
        @data_sets = []
        @binding_processes_group = {}
        @including_files = {}
        @reset_constraint_views = {}
        @reset_text_views = {}
        @partial_bindings = []
        @current_partial_depth = 0
      end

      def analyze_json(file_name, loaded_json)
        json = loaded_json
        current_view = {"name": "", "type": ""}
        
        # Check if this is an include element with data
        if json["include"] && !json["type"]
          include_name = json["include"]
          data_bindings = json["data"]
          process_include_element(file_name, include_name, json, data_bindings)
          # Track this as a partial binding only if we're at the top level
          track_partial_binding(include_name, data_bindings) if @current_partial_depth == 0
          return
        end
        
        unless json["style"].nil?
          file_path = "#{@style_path}/#{json["style"]}.json"
          if File.exist?(file_path) && File.file?(file_path)
            File.open(file_path, "r") do |file|
              json_string = file.read
              style_json = JSON.parse(json_string)
              json = json.merge(style_json)
            end
          elsif File.exist?(file_path)
            puts "Warning: Style path is not a file: #{file_path}"
          else
            puts "Warning: Style file not found: #{file_path}"
          end
        end
        json.each do |key,value|
          case key
          when "data"
            # Only add data if we're not inside a partial
            @data_sets += value if @current_partial_depth == 0
          when "type"
            @import_module_manager.add_import_module_for_type(value)
            current_view["type"] = value
          when "id"
            process_id_element(json, value, current_view)
          when "child"
            value.each do |child_json|
              analyze_json(file_name, child_json)
            end
          when "include"
            process_include_element(file_name, value, json, nil)
            # Track this as a partial binding only if we're at the top level
            track_partial_binding(value) if @current_partial_depth == 0
          when "onClick"
            @ui_control_event_manager.add_click_event(current_view["name"], value)
          when "onLongPress"
            @ui_control_event_manager.add_long_press_event(current_view["name"], value)
          when "onPan"
            @ui_control_event_manager.add_pan_event(current_view["name"], value)
          when "onPinch"
            @ui_control_event_manager.add_pinch_event(current_view["name"], value)
          else
            process_binding_element(json, key, value, current_view)
          end
        end
      end

      def analyze_binding_process(binding_process)
        view = binding_process[:view]
        view_name = view["name"]
        puts "Analyzing binding process: #{binding_process.inspect}"
        puts view
        raise "View Id should be set. #{binding_process}" if view_name.nil?
        key = binding_process[:key]

        value = binding_process[:value]
        if value.is_a?(String)
          value = value.gsub(/this/, view["name"]).gsub(/'/, "\"")
        end

        # ハンドラーを取得
        handler = ViewBindingHandlerFactory.create_handler(view["type"], @binding_content, @reset_text_views, @reset_constraint_views)
        
        # 共通処理を試行
        handled = handler.handle_common_binding(view_name, key, value)
        
        # 共通処理で処理されなかった場合のみ、view type固有の処理を試行
        unless handled
          handler.handle_specific_binding(view_name, key, value)
        end
      end

      def generate_invalidate_methods
        @invalidate_methods_content = String.new
        
        @binding_processes_group.each do |group, value|
          method_content = String.new
          @reset_constraint_views = {}
          @reset_text_views = {}
          
          # グループ名に基づいてメソッド名を決定
          method_name = case group
                       when "all"
                         "All"
                       when ""
                         ""
                       else
                         group.capitalize.camelize
                       end
          
          method_content << "\n"
          method_content << "    func invalidate#{method_name}(resetForm: Bool = false, formInitialized: Bool = false) {\n"
          method_content << "        if resetForm {\n"
          method_content << "            isInitialized = false\n"
          method_content << "        }\n"
          
          # Call invalidate on partial bindings FIRST (children before parent)
          unless method_name.empty?
            @partial_bindings.each do |partial|
              # Skip partials that don't have any bindings
              next unless partial[:has_bindings]
              
              # Check if partial has this binding group
              partial_has_group = case group
                                when "all"
                                  true  # All partials have invalidateAll
                                when ""
                                  true  # All partials have invalidate (no suffix)
                                else
                                  partial[:binding_groups].include?(group)
                                end
              
              if partial_has_group
                method_content << "        \n"
                method_content << "        // Propagate invalidate to partial binding (child first)\n"
                method_content << "        #{partial[:property_name]}Binding.invalidate#{method_name}(resetForm: resetForm, formInitialized: formInitialized)\n"
              end
            end
          end
          
          # 各バインディングプロセスを処理（一時的にbinding_contentを保存）
          temp_binding_content = @binding_content
          @binding_content = String.new
          
          value.each do |binding_process|
            analyze_binding_process binding_process
          end
          
          # テキストビューのリセット処理
          generate_text_view_resets
          
          # 制約ビューのリセット処理  
          generate_constraint_view_resets
          
          # Parent's own invalidate logic comes AFTER children
          method_content << @binding_content
          method_content << "        if formInitialized {\n"
          method_content << "            isInitialized = true\n"
          method_content << "        }\n"
          method_content << "    }\n"
          
          @invalidate_methods_content << method_content
          @binding_content = temp_binding_content
        end
        
        @binding_content << @invalidate_methods_content
      end

      private

      def track_partial_binding(partial_name, parent_data_bindings = {})
        # Convert partial name to binding class name
        # e.g., "common/navigation_bar" -> "NavigationBarBinding"
        # e.g., "header_section" -> "HeaderSectionBinding"
        base_name = File.basename(partial_name)
        binding_name = base_name.split('_').map(&:capitalize).join + "Binding"
        
        # Add to partial_bindings list if not already present
        unless @partial_bindings.any? { |p| p[:name] == partial_name }
          # Analyze partial JSON to determine which binding groups it has
          partial_file_path = File.join(@layout_path, "#{partial_name}.json")
          binding_groups = []
          has_bindings = false
          
          if File.exist?(partial_file_path)
            begin
              partial_json = JSON.parse(File.read(partial_file_path))
              binding_groups = analyze_binding_groups(partial_json)
              has_bindings = has_binding_data(partial_json)
            rescue => e
              puts "Warning: Could not analyze partial binding groups: #{e.message}"
            end
          end
          
          # Convert to camelCase for property name
          property_name = base_name.split(/[_-]/).map.with_index { |word, i| 
            i == 0 ? word : word.capitalize 
          }.join
          
          @partial_bindings << {
            name: partial_name,
            binding_class: binding_name,
            property_name: property_name,
            binding_groups: binding_groups,
            has_bindings: has_bindings,
            parent_data_bindings: parent_data_bindings
          }
        end
      end
      
      def analyze_binding_groups(json)
        groups = Set.new
        
        # Recursively find all binding_group values in the JSON
        if json.is_a?(Hash)
          json.each do |key, value|
            if key == "binding_group" && value.is_a?(Array)
              groups.merge(value)
            elsif value.is_a?(Hash) || value.is_a?(Array)
              groups.merge(analyze_binding_groups(value))
            end
          end
        elsif json.is_a?(Array)
          json.each do |item|
            if item.is_a?(Hash) || item.is_a?(Array)
              groups.merge(analyze_binding_groups(item))
            end
          end
        end
        
        groups.to_a
      end

      def has_binding_data(json)
        # Check if JSON has any data bindings (@{...} patterns)
        if json.is_a?(Hash)
          json.each do |key, value|
            if value.is_a?(String) && value.start_with?("@{")
              return true
            elsif value.is_a?(Hash) || value.is_a?(Array)
              return true if has_binding_data(value)
            end
          end
        elsif json.is_a?(Array)
          json.each do |item|
            if item.is_a?(Hash) || item.is_a?(Array)
              return true if has_binding_data(item)
            end
          end
        end
        
        false
      end

      def process_id_element(json, value, current_view)
        puts "id: #{value}"
        view_type = @view_type_set[json["type"].to_sym]
        raise "View Type Not found" if view_type.nil?
        variable_name = value.camelize
        variable_name[0] = variable_name[0].chr.downcase
        current_view["name"] = variable_name
        return if @super_binding != "Binding" && !JsonLoaderConfig::IGNORE_ID_SET[value.to_sym].nil?
        
        # Skip weak var generation if we're inside a partial binding
        return if @current_partial_depth > 0
        
        weak_var_line = "    weak var #{variable_name}: #{view_type}!\n"
        @binding_content << weak_var_line
        @weak_vars_content << weak_var_line
      end

      def process_include_element(file_name, value, json, data_bindings = nil)
        if @including_files[file_name].nil?
          @including_files[file_name] = [value]
        else
          @including_files[file_name] << value
          @including_files[file_name].uniq!
        end
        
        # サブディレクトリを含むパスをサポート
        # 直接指定されたパスでファイルを探す（_プレフィックスは不要）
        file_path = File.join(@layout_path, "#{value}.json")
        
        # ファイルが見つからない場合はエラー
        unless File.exist?(file_path)
          raise "Include file not found: #{file_path}"
        end
        
        # ディレクトリの場合はエラー
        unless File.file?(file_path)
          raise "Include path is not a file: #{file_path}"
        end
        
        File.open(file_path, "r") do |file|
          json_string = file.read
          
          # Replace variables from parent
          unless json["variables"].nil?
            json["variables"].each do |k,v|
              puts k
              puts v
              json_string.gsub!(k,v.to_s)
            end
          end
          
          included_json = JSON.parse(json_string)
          
          # If data bindings are provided, store them for later processing
          # but don't add them to the JSON structure itself
          @parent_data_bindings = data_bindings || {}
          
          # Increment depth before processing included file
          @current_partial_depth += 1
          analyze_json(file_name, included_json)
          # Decrement depth after processing
          @current_partial_depth -= 1
        end
      end

      def process_binding_element(json, key, value, current_view)
        if value.is_a?(String) && value.start_with?("@{")
          # Skip adding to binding processes if we're inside a partial
          # Partials handle their own binding processes
          return if @current_partial_depth > 0
          
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

      def generate_text_view_resets
        @reset_text_views.each do |key, value|
          text = value[:text].nil? ? "#{key}?.attributedText?.string" : value[:text]
          @binding_content << "        #{key}?.linkable ?? false ? #{key}?.applyLinkableAttributedText(#{text}) : #{key}?.applyAttributedText(#{text})\n"
        end
      end

      def generate_constraint_view_resets
        @reset_constraint_views.keys.each do |key|
          @binding_content << "        #{key}.resetConstraintInfo()\n"
        end
      end
    end
  end
end