class ProjectPaths
  attr_reader :view_path, :layout_path, :style_path, :bindings_path, :source_path, :core_path, :ui_path, :base_path
  
  def initialize(view_path:, layout_path:, style_path:, bindings_path:, source_path:, core_path: nil, ui_path: nil, base_path: nil)
    @view_path = view_path
    @layout_path = layout_path
    @style_path = style_path
    @bindings_path = bindings_path
    @source_path = source_path
    @core_path = core_path
    @ui_path = ui_path
    @base_path = base_path
  end
end