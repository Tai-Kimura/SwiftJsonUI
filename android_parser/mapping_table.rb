class MappingTable
  def self.view_types_map
    @@view_types_map
  end
  @@view_types_map = {
    "View": "View",
    "Linear": "LinearLayout",   
    "Relative": "RelativeLayout", 
    "Scroll": "ScrollView",  
    "Collection": "RecyclerView",  
    "Label": "TextView",   
    "Button": "Button",  
    "Image": "ImageView",
    "NetworkImage": "NetworkImageView",    
    "TextField": "EditText", 
    "TextView": "EditText",    
    "Switch": "Switch",  
    "SelectBox": "Spinner"   
  }
  def self.attributes_map
    @@attributes_map
  end
  @@attributes_map = {
    "id": "id",
    "style": "style",
    "width": "layout_width",
    "height": "layout_height",
    "weight": "layout_weight",
    "orientation": "orientation",
    "paddingTop": "paddingTop",
    "paddingLeft": "paddingLeft",
    "paddingBottom": "paddingBottom",
    "paddingRight": "paddingRight",    
    "topMargin": "layout_marginTop",
    "leftMargin": "layout_marginLeft",
    "bottomMargin": "layout_marginBottom",
    "rightMargin": "layout_marginRight",
    "alignTopOfView": "layout_above",
    "alignLeftOfView": "layout_toLeftOf",
    "alignBottomOfView": "layout_below",
    "alignRightOfView": "layout_toRightOf",
    "alignTopView": "layout_alignTop",
    "alignLeftView": "layout_alignLeft",
    "alignBottomView": "layout_alignBottom",
    "alignRightView": "layout_alignRight",
    "alignTop": "layout_alignParentTop",
    "alignLeft": "layout_alignParentLeft",
    "alignBottom": "layout_alignParentBottom",
    "alignRight": "layout_alignParentRight",
    "centerVertical": "layout_centerVertical",
    "centerHorizontal": "layout_centerHorizontal",
    "text": "text",
    "fontColor": "textColor",
    "fontSize": "textSize",
    "hint": "hint",
    "textAlign": "gravity",
    "input": "inputType",
    "gravity": "gravity",
    "src": "src",
    "onclick": "onClick"
  }
end