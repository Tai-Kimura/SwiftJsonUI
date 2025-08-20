# frozen_string_literal: true

require_relative '../core/config_manager'

module SjuiTools
  module UIKit
    class JsonLoaderConfig
      VIEW_TYPE_SET = {
        "View": "SJUIView",
        "SafeAreaView": "SJUIView",
        "GradientView": "GradientView",
        "Blur": "SJUIVisualEffectView",
        "CircleView": "SJUICircleView",
        "Scroll": "SJUIScrollView",
        "Table": "SJUITableView",
        "Collection": "SJUICollectionView",
        "Segment": "SJUISegmentedControl",
        "Label": "SJUILabel",
        "IconLabel": "SJUILabelWithIcon",
        "Button": "SJUIButton",
        "Image": "SJUIImageView",
        "NetworkImage": "NetworkImageView",
        "CircleImage": "CircleImageView",
        "Web": "WKWebView",
        "TextField": "SJUITextField",
        "TextView": "SJUITextView",
        "Switch": "SJUISwitch",
        "Radio": "SJUIRadioButton",
        "Check": "SJUICheckBox",
        "Progress": "UIProgressView",
        "Slider": "UISlider",
        "SelectBox": "SJUISelectBox",
        "Indicator": "UIActivityIndicatorView",
        "Triangle": "TriangleView"
      }

      IGNORE_ID_SET = {}

      IGNORE_DATA_SET = {}
      
      IGNORE_BINDING_SET = {}
      
      # Load ignore sets from config if available
      def self.load_ignore_sets_from_config
        config = Core::ConfigManager.load_config
        
        # Load ignore_id_set from config
        if config['ignore_id_set'].is_a?(Array)
          config['ignore_id_set'].each do |id|
            IGNORE_ID_SET[id] = true
          end
        end
        
        # Load ignore_data_set from config
        if config['ignore_data_set'].is_a?(Array)
          config['ignore_data_set'].each do |data|
            IGNORE_DATA_SET[data] = true
          end
        end
        
        # Load ignore_binding_set from config
        if config['ignore_binding_set'].is_a?(Array)
          config['ignore_binding_set'].each do |binding|
            IGNORE_BINDING_SET[binding] = true
          end
        end
      end
    end
  end
end