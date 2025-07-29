require 'json'

class ConfigManager
  DEFAULT_CONFIG = {
    'project_name' => '',
    'project_file_name' => '',
    'source_directory' => '',
    'layouts_directory' => 'Layouts',
    'bindings_directory' => 'Bindings',
    'view_directory' => 'View',
    'styles_directory' => 'Styles',
    'build_settings' => {
      'auto_build' => false,
      'clean_before_build' => false
    },
    'generator_settings' => {
      'create_layout_file' => true,
      'create_binding_file' => true,
      'add_to_xcode_project' => true
    },
    'custom_view_types' => {},
    'hot_loader_directory' => '',
    'use_network' => true
  }.freeze

  def self.load_config(base_dir = nil)
    base_dir ||= File.dirname(__FILE__)
    config_file = File.join(base_dir, 'config.json')
    
    if File.exist?(config_file)
      begin
        file_content = File.read(config_file)
        parsed_config = JSON.parse(file_content)
        
        # Merge with default config to ensure all keys exist
        config = DEFAULT_CONFIG.merge(parsed_config)
        
        
        return config
      rescue JSON::ParserError => e
        puts "Warning: Failed to parse config.json: #{e.message}"
        puts "Using default configuration."
      rescue => e
        puts "Warning: Failed to read config.json: #{e.message}"
        puts "Using default configuration."
      end
    end
    
    DEFAULT_CONFIG.dup
  end
  
  def self.get_source_directory(base_dir = nil)
    config = load_config(base_dir)
    source_dir = config['source_directory']
    # source_directoryが空の場合は空文字列を返す（プロジェクトディレクトリ直下を意味）
    source_dir.nil? || source_dir.strip.empty? ? '' : source_dir
  end
  
  def self.get_layouts_directory(base_dir = nil)
    config = load_config(base_dir)
    config['layouts_directory']
  end
  
  def self.get_bindings_directory(base_dir = nil)
    config = load_config(base_dir)
    config['bindings_directory']
  end
  
  def self.get_view_directory(base_dir = nil)
    config = load_config(base_dir)
    config['view_directory']
  end
  
  def self.get_styles_directory(base_dir = nil)
    config = load_config(base_dir)
    config['styles_directory']
  end
  
  def self.get_project_file_name(base_dir = nil)
    config = load_config(base_dir)
    config['project_file_name']
  end
  
  # source_directoryを考慮したbindings_pathを構築
  def self.get_bindings_path(parent_dir, base_dir = nil)
    config = load_config(base_dir)
    source_dir = get_source_directory(base_dir)
    bindings_dir = config['bindings_directory']
    
    if source_dir.empty?
      # source_directoryが空の場合はプロジェクト直下
      File.join(parent_dir, bindings_dir)
    else
      # source_directoryが指定されている場合
      File.join(parent_dir, source_dir, bindings_dir)
    end
  end
  
  # source_directoryのフルパスを構築
  def self.get_source_path(parent_dir, base_dir = nil)
    source_dir = get_source_directory(base_dir)
    
    if source_dir.empty?
      # source_directoryが空の場合はプロジェクト直下
      parent_dir
    else
      # source_directoryが指定されている場合
      File.join(parent_dir, source_dir)
    end
  end
  
  def self.get_custom_view_types(base_dir = nil)
    config = load_config(base_dir)
    config['custom_view_types'] || {}
  end
  
  def self.get_hot_loader_directory(base_dir = nil)
    config = load_config(base_dir)
    hot_loader_dir = config['hot_loader_directory']
    
    # 空の場合はプロジェクト名をデフォルトとして使用
    if hot_loader_dir.nil? || hot_loader_dir.strip.empty?
      get_project_file_name(base_dir)
    else
      hot_loader_dir
    end
  end
  
  def self.get_use_network(base_dir = nil)
    config = load_config(base_dir)
    # デフォルトでtrueを返す
    config.fetch('use_network', true)
  end
end