class ProjectFinder
  def self.find_project_file(starting_dir = Dir.pwd)
    search_dir = File.expand_path(starting_dir)
    found_projects = []
    
    STDERR.puts "Searching for Xcode projects from: #{search_dir}"
    
    # 最大3階層まで検索（深すぎる検索を避ける）
    3.times do |level|
      STDERR.puts "  Searching level #{level + 1}: #{search_dir}"
      
      # 現在のディレクトリ内で.xcodeprojディレクトリを検索
      Dir.glob("#{search_dir}/*.xcodeproj").each do |xcodeproj_dir|
        pbxproj_path = File.join(xcodeproj_dir, "project.pbxproj")
        if File.exist?(pbxproj_path)
          STDERR.puts "    Found: #{pbxproj_path}"
          found_projects << pbxproj_path
        end
      end
      
      # 一つ上の階層に移動
      parent_dir = File.dirname(search_dir)
      break if parent_dir == search_dir # ルートディレクトリに到達
      search_dir = parent_dir
    end
    
    if found_projects.empty?
      raise "Could not find project.pbxproj file. Please ensure you're in a project directory with an Xcode project."
    elsif found_projects.length == 1
      STDERR.puts "Found Xcode project: #{found_projects.first}"
      return found_projects.first
    else
      # 複数見つかった場合
      project_names = found_projects.map { |path| detect_project_name(path) }.join(", ")
      raise "Multiple Xcode projects found: #{project_names}. Please specify one using --project <name> option."
    end
  end

  def self.find_project_file_by_name(starting_dir = Dir.pwd, project_name)
    search_dir = File.expand_path(starting_dir)
    target_xcodeproj = "#{project_name}.xcodeproj"
    
    STDERR.puts "Searching for project: #{project_name} from: #{search_dir}"
    
    # 最大3階層まで検索
    3.times do |level|
      STDERR.puts "  Searching level #{level + 1}: #{search_dir}"
      
      # 指定された名前のxcodeprojディレクトリを検索
      xcodeproj_path = File.join(search_dir, target_xcodeproj)
      if File.directory?(xcodeproj_path)
        pbxproj_path = File.join(xcodeproj_path, "project.pbxproj")
        if File.exist?(pbxproj_path)
          STDERR.puts "Found Xcode project: #{pbxproj_path}"
          return pbxproj_path
        end
      end
      
      # サブディレクトリも検索
      xcodeproj_pattern = File.join(search_dir, "*", target_xcodeproj)
      Dir.glob(xcodeproj_pattern).each do |proj_dir|
        pbxproj_path = File.join(proj_dir, "project.pbxproj")
        if File.exist?(pbxproj_path)
          STDERR.puts "Found Xcode project: #{pbxproj_path}"
          return pbxproj_path
        end
      end
      
      # 一つ上の階層に移動
      parent_dir = File.dirname(search_dir)
      break if parent_dir == search_dir # ルートディレクトリに到達
      search_dir = parent_dir
    end
    
    # 見つからない場合は利用可能なプロジェクトをリストアップしてエラー
    available_projects = find_all_projects(File.expand_path(starting_dir))
    if available_projects.empty?
      raise "Could not find any Xcode projects."
    else
      available_names = available_projects.map { |path| detect_project_name(path) }.join(", ")
      raise "Could not find project '#{project_name}.xcodeproj'. Available projects: #{available_names}"
    end
  end

  def self.find_all_projects(starting_dir = Dir.pwd)
    search_dir = File.expand_path(starting_dir)
    projects = []
    
    # 最大5階層まで検索
    5.times do
      # 現在のディレクトリ内で.xcodeprojディレクトリを検索
      Dir.glob("#{search_dir}/**/*.xcodeproj").each do |xcodeproj_dir|
        pbxproj_path = File.join(xcodeproj_dir, "project.pbxproj")
        if File.exist?(pbxproj_path)
          projects << pbxproj_path
        end
      end
      
      # 一つ上の階層に移動
      parent_dir = File.dirname(search_dir)
      break if parent_dir == search_dir # ルートディレクトリに到達
      search_dir = parent_dir
    end
    
    projects.uniq
  end

  def self.detect_project_name(project_file_path)
    # project.pbxprojのパスから.xcodeprojディレクトリ名を取得してプロジェクト名を推定
    xcodeproj_dir = File.dirname(project_file_path)
    project_name = File.basename(xcodeproj_dir, ".xcodeproj")
    project_name
  end

  def self.get_project_root(project_file_path)
    # binding_builderフォルダの親ディレクトリを取得
    # このスクリプトはbinding_builderフォルダ内で実行される前提
    binding_builder_dir = File.dirname(__FILE__)
    File.dirname(binding_builder_dir)
  end
  
  # ConfigManagerを使用してパスを設定
  def self.setup_paths(base_dir = nil, project_file_path = nil)
    require_relative 'config_manager'
    require_relative 'project_paths'
    
    base_dir ||= File.dirname(__FILE__)
    config = ConfigManager.load_config(base_dir)
    
    # binding_builderディレクトリと同じ階層をベースディレクトリとする
    # base_dirがxcode_project/setup/の場合は2階層上がbinding_builder、そのさらに1階層上が目標
    # base_dirがbinding_builderの場合は1階層上が目標
    if base_dir.include?('/xcode_project/')
      # xcode_project内のファイルから実行された場合
      binding_builder_dir = File.dirname(File.dirname(base_dir))
      base_parent_dir = File.dirname(binding_builder_dir)
    else
      # binding_builderから直接実行された場合
      base_parent_dir = File.dirname(base_dir)
    end
    
    # 各ディレクトリをbinding_builderと同じ階層に作成
    core_path = File.join(base_parent_dir, 'Core')
    ui_path = File.join(core_path, 'UI')
    base_path = File.join(core_path, 'Base')
    
    ProjectPaths.new(
      view_path: File.join(base_parent_dir, config['view_directory']),
      layout_path: File.join(base_parent_dir, config['layouts_directory']),
      style_path: File.join(base_parent_dir, config['styles_directory']),
      bindings_path: File.join(base_parent_dir, config['bindings_directory']),
      source_path: base_parent_dir,
      core_path: core_path,
      ui_path: ui_path,
      base_path: base_path
    )
  end
  
  # プロジェクトファイルパスの設定
  def self.setup_project_file(base_dir = nil, project_name = nil)
    require_relative 'config_manager'
    
    base_dir ||= File.dirname(__FILE__)
    config = ConfigManager.load_config(base_dir)
    
    if project_name
      find_project_file_by_name(base_dir, project_name)
    elsif config['project_file_name'] && !config['project_file_name'].empty?
      find_project_file_by_name(base_dir, config['project_file_name'])
    else
      begin
        find_project_file(base_dir)
      rescue => e
        STDERR.puts "Warning: Could not find project file automatically. #{e.message}"
        nil
      end
    end
  end
end