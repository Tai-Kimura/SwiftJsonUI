# frozen_string_literal: true

require_relative 'json_loader_config'
require_relative 'view_binding_handler_factory'
require_relative 'string_module'

module SjuiTools
  module Binding
    class JsonAnalyzer
      attr_reader :binding_content, :data_sets, :binding_processes_group, :including_files, :reset_constraint_views, :weak_vars_content, :invalidate_methods_content

      def initialize(import_module_manager, ui_control_event_manager, layout_path, style_path, super_binding, view_type_set)
        @import_module_manager = import_module_manager
        @ui_control_event_manager = ui_control_event_manager
        @layout_path = layout_path
        @style_path = style_path
        @super_binding = super_binding
        @view_type_set = view_type_set
        @binding_content = ""
        @weak_vars_content = ""
        @invalidate_methods_content = ""
        @data_sets = []
        @binding_processes_group = {}
        @including_files = {}
        @reset_constraint_views = {}
        @reset_text_views = {}
      end

      def analyze_json(file_name, loaded_json)
        json = loaded_json
        current_view = {"name": "", "type": ""}
        unless json["style"].nil?
          file_path = "#{@style_path}/#{json["style"]}.json"
          File.open(file_path, "r") do |file|
            json_string = file.read
            style_json = JSON.parse(json_string)
            json = json.merge(style_json)
          end
        end
        json.each do |key,value|
          case key
          when "data"
            @data_sets += value
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
            process_include_element(file_name, value, json)
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
        @invalidate_methods_content = ""
        
        @binding_processes_group.each do |group, value|
          method_content = ""
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
          
          # 各バインディングプロセスを処理（一時的にbinding_contentを保存）
          temp_binding_content = @binding_content
          @binding_content = ""
          
          value.each do |binding_process|
            analyze_binding_process binding_process
          end
          
          # テキストビューのリセット処理
          generate_text_view_resets
          
          # 制約ビューのリセット処理  
          generate_constraint_view_resets
          
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

      def process_id_element(json, value, current_view)
        puts "id: #{value}"
        view_type = @view_type_set[json["type"].to_sym]
        raise "View Type Not found" if view_type.nil?
        variable_name = value.camelize
        variable_name[0] = variable_name[0].chr.downcase
        current_view["name"] = variable_name
        return if @super_binding != "Binding" && !JsonLoaderConfig::IGNORE_ID_SET[value.to_sym].nil?
        weak_var_line = "    weak var #{variable_name}: #{view_type}!\n"
        @binding_content << weak_var_line
        @weak_vars_content << weak_var_line
      end

      def process_include_element(file_name, value, json)
        if @including_files[file_name].nil?
          @including_files[file_name] = [value]
        else
          @including_files[file_name] << value
          @including_files[file_name].uniq!
        end
        
        # サブディレクトリを含むパスをサポート
        # パスを分割して、ファイル名部分に_プレフィックスを追加
        if value.include?('/')
          # サブディレクトリがある場合
          dir_parts = value.split('/')
          file_base = dir_parts.pop
          dir_path = dir_parts.join('/')
          
          # まずpartial用の_プレフィックス付きファイルを探す
          file_path = File.join(@layout_path, dir_path, "_#{file_base}.json")
          if !File.exists?(file_path)
            # 次に通常のファイルを探す
            file_path = File.join(@layout_path, "#{value}.json")
          end
        else
          # サブディレクトリがない場合
          # まずpartial用の_プレフィックス付きファイルを探す
          file_path = File.join(@layout_path, "_#{value}.json")
          if !File.exists?(file_path)
            # 次に通常のファイルを探す
            file_path = File.join(@layout_path, "#{value}.json")
          end
        end
        
        # ファイルが見つからない場合はエラー
        unless File.exists?(file_path)
          if value.include?('/')
            dir_parts = value.split('/')
            file_base = dir_parts.pop
            dir_path = dir_parts.join('/')
            tried_paths = "#{File.join(@layout_path, dir_path, "_#{file_base}.json")} and #{File.join(@layout_path, "#{value}.json")}"
          else
            tried_paths = "#{File.join(@layout_path, "_#{value}.json")} and #{File.join(@layout_path, "#{value}.json")}"
          end
          raise "Include file not found: #{value} (tried #{tried_paths})"
        end
        
        File.open(file_path, "r") do |file|
          json_string = file.read
          unless json["variables"].nil?
            json["variables"].each do |k,v|
              puts k
              puts v
              json_string.gsub!(k,v.to_s)
            end
          end
          included_json = JSON.parse(json_string)
          analyze_json(file_name, included_json)
        end
      end

      def process_binding_element(json, key, value, current_view)
        if value.is_a?(String) && value.start_with?("@{")
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