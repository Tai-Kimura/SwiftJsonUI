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

  IGNORE_ID_SET = {
    "navi": true,
    "title_label": true,
    "scroll_view": true,
    "back": true,
    "navi_back_icon": true,
    "navi_back_label": true,
    "navi_right_btn": true,
    "navi_right_label": true,
    "navi_right_icon": true
  }

  IGNORE_DATA_SET = {
    "naviTitle": true,
    "naviBackTitle": true,
    "naviBackIcon": true,
    "naviRightTitle": true,
    "naviRightIcon": true,
    "isInitialized": true
  }
end