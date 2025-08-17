require_relative 'view_converter'

module SjuiTools
  module SwiftUI
    module Views
      class SafeAreaViewConverter < ViewConverter
        def initialize(component, indent_level = 0, action_manager = nil, converter_factory = nil, view_registry = nil, binding_registry = nil)
          super
          # SafeAreaView is essentially a View that respects safe area
          # Set flag to skip ignoresSafeArea modifier
          @skip_ignore_safe_area = true
        end

        protected

        def should_ignore_safe_area?
          # SafeAreaView should NOT ignore safe area
          false
        end

        def apply_safe_area_modifier?
          # SafeAreaView should NOT apply .ignoresSafeArea()
          false
        end
      end
    end
  end
end