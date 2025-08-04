# frozen_string_literal: true

module SjuiTools
  module Binding
    class ImportModuleManager
      # クラスレベルでタイプとインポートモジュールのマッピングを管理
      @@type_import_mapping = {
        "Web" => "WebKit"
      }

      # build.rbなどから拡張可能なクラスメソッド
      def self.add_type_import_mapping(view_type, import_module)
        @@type_import_mapping[view_type] = import_module
      end

      def self.type_import_mapping
        @@type_import_mapping
      end

      def initialize
        @import_modules = {}
      end

      def add_import_module_for_type(view_type)
        import_module = @@type_import_mapping[view_type]
        if import_module
          @import_modules[import_module] = true
        end
      end

      def reset
        @import_modules = {}
      end

      def generate_import_statements
        import_content = "import UIKit\nimport SwiftJsonUI\n"
        @import_modules.each do |import_module, v|
          import_content << "import #{import_module}\n"
        end
        import_content
      end
    end
  end
end