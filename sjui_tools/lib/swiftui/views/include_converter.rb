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
        
        # ファイル名からビュー名を生成（_プレフィックスなし）
        view_name = include_path.split('/').last.split('_').map(&:capitalize).join
        
        # ビュー名に'View'サフィックスが含まれていない場合は追加
        view_name += 'View' unless view_name.end_with?('View')
        
        # 変数の処理（将来的な実装用）
        if @component['variables']
          add_line "// Variables would be passed here: #{@component['variables'].to_json}"
        end
        
        # dataの処理（将来的な実装用）
        if @component['data']
          add_line "// Data would be passed here: #{@component['data'].to_json}"
        end
        
        # includeされたビューを直接参照
        add_line "#{view_name}()"
        
        # 共通プロパティの適用
        apply_modifiers
        
        generated_code
      end
      end
    end
  end
end