require_relative 'base_view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class IncludeConverter < BaseViewConverter
      def convert
        # includeプロパティからファイル名を取得
        include_path = @component['include']
        
        unless include_path
          raise "Include component must have 'include' property"
        end
        
        # ファイル名からビュー名を生成
        # included_1 -> Included1View, main_menu -> MainMenuView
        base_name = include_path.split('/').last
        view_name = base_name.split('_').map(&:capitalize).join + 'View'
        
        # shared_dataとdataをマージ
        merged_data = {}
        
        # shared_dataを先に追加
        if @component['shared_data'] && @component['shared_data'].is_a?(Hash)
          merged_data.merge!(@component['shared_data'])
        end
        
        # dataで上書き
        if @component['data'] && @component['data'].is_a?(Hash)
          merged_data.merge!(@component['data'])
        end
        
        # マージしたデータがある場合
        unless merged_data.empty?
          # @{}参照があるかチェック
          has_reactive_data = merged_data.values.any? { |v| v.is_a?(String) && v.match?(/@\{/) }
          
          if has_reactive_data
            # リアクティブなデータ用 - SwiftUIのビューを再作成させる
            # IDを使って親データが変わったときに再レンダリング
            reactive_keys = extract_reactive_keys(merged_data)
            # Create a combined string for the ID
            id_parts = reactive_keys.map { |key| "\\(viewModel.data.#{key})" }
            id_expression = id_parts.join("_")
            
            dict_content = process_data_hash(merged_data)
            add_line "#{view_name}(data: [#{dict_content}])"
            indent do
              add_line ".id(\"#{id_expression}\")"
            end
          else
            # 静的データの場合は今まで通り
            dict_content = process_data_hash(merged_data)
            add_line "#{view_name}(data: [#{dict_content}])"
          end
        else
          # データがない場合
          add_line "#{view_name}()"
        end
        
        # 共通プロパティの適用
        apply_modifiers
        
        generated_code
      end
      
      private
      
      def process_data_hash(hash)
        hash.map { |key, value|
          formatted_value = format_value(value)
          "\"#{key}\": #{formatted_value}"
        }.join(", ")
      end
      
      def extract_reactive_keys(hash)
        keys = []
        hash.each do |_, value|
          if value.is_a?(String) && value.match?(/@\{([^}]+)\}/)
            value.scan(/@\{([^}]+)\}/) do |match|
              var_name = match[0]
              # Remove 'this.' prefix if present
              var_name = var_name.gsub(/^this\./, '')
              keys << var_name unless keys.include?(var_name)
            end
          end
        end
        keys
      end
      
      def format_value(value)
        case value
        when String
          if value.match?(/@\{([^}]+)\}/)
            # @{xxx}形式の場合、変数参照として処理
            value.gsub(/@\{([^}]+)\}/) do |match|
              var_name = $1
              # this.をviewModel.data.に変換
              if var_name.start_with?('this.')
                var_name.gsub(/^this\./, 'viewModel.data.')
              else
                # this.がない場合もviewModel.data.を付ける
                "viewModel.data.#{var_name}"
              end
            end
          else
            # 通常の文字列
            "\"#{value}\""
          end
        when Hash
          # ネストされたHashの処理
          "[#{process_data_hash(value)}]"
        when Array
          # 配列の処理
          "[#{value.map { |v| format_value(v) }.join(", ")}]"
        when Numeric
          value.to_s
        when TrueClass, FalseClass
          value.to_s
        when NilClass
          "nil"
        else
          "\"#{value}\""
        end
      end
      end
    end
  end
end