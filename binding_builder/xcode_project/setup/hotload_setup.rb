#!/usr/bin/env ruby

require "fileutils"
require_relative "../pbxproj_manager"

class HotLoadSetup < PbxprojManager
  def initialize(project_file_path)
    super(project_file_path)
  end

  def setup_hotload_build_phase
    puts "Setting up HotLoad Build Phase..."
    
    safe_pbxproj_operation([], []) do
      # Build Phase Script を追加
      add_hotload_build_phase_script
      
      # AppDelegateにHotLoad設定を追加（まだの場合）
      setup_app_delegate_hotload
      
      puts "HotLoad Build Phase setup completed successfully"
    end
  end

  private

  def add_hotload_build_phase_script
    return unless File.exist?(@project_file_path)
    puts "Adding HotLoad Build Phase script..."
    
    # バックアップ作成
    backup_path = create_backup(@project_file_path)
    
    begin
      # プロジェクトファイルを読み込み
      content = File.read(@project_file_path)
      
      # 既にHotLoad Build Phaseが存在するかチェック
      if content.include?("SwiftJsonUI HotLoad")
        puts "HotLoad Build Phase already exists"
        cleanup_backup(backup_path)
        return
      end
      
      # メインターゲットのbuildPhasesセクションを見つける
      target_pattern = /(\w+) \/\* #{Regexp.escape(get_target_name)} \*\/ = \{[^}]*buildPhases = \(\s*([^)]*)\s*\);/m
      
      match = content.match(target_pattern)
      unless match
        puts "Warning: Could not find main target buildPhases section"
        cleanup_backup(backup_path)
        return
      end
      
      target_id = match[1]
      build_phases = match[2]
      
      # 新しいRun Script Build PhaseのUUIDを生成
      script_uuid = generate_uuid
      script_build_file_uuid = generate_uuid
      
      # Run Script Build Phaseを追加
      script_phase_content = generate_hotload_script_phase(script_uuid)
      
      # より安全なパターンマッチング
      content = content.gsub(
        /(#{Regexp.escape(target_id)} \/\* #{Regexp.escape(get_target_name)} \*\/ = \{[^}]*buildPhases = \(\s*)([^)]*?)(\s*\);)/m,
        "\\1#{script_uuid} /* SwiftJsonUI HotLoad */,\n\t\t\t\t\\2\\3"
      )
      
      # PBXShellScriptBuildPhase sectionを見つけて追加
      shell_script_section_pattern = /(\/\* Begin PBXShellScriptBuildPhase section \*\/.*?)(\/\* End PBXShellScriptBuildPhase section \*\/)/m
      
      if content.match(shell_script_section_pattern)
        # 既存のセクションに追加
        content = content.gsub(shell_script_section_pattern, "\\1#{script_phase_content}\n\\2")
      else
        # セクションが存在しない場合は新規作成
        sections_end_pattern = /(\/\* End PBXSourcesBuildPhase section \*\/)/
        new_section = "\n/* Begin PBXShellScriptBuildPhase section */\n#{script_phase_content}\n/* End PBXShellScriptBuildPhase section */\n"
        content = content.gsub(sections_end_pattern, "\\1#{new_section}")
      end
      
      # ファイルに書き戻し
      File.write(@project_file_path, content)
      
      # 整合性をチェック
      if validate_pbxproj(@project_file_path)
        puts "✅ HotLoad Build Phase script added successfully"
        cleanup_backup(backup_path)
      else
        puts "❌ pbxproj file validation failed, rolling back..."
        FileUtils.copy(backup_path, @project_file_path)
        cleanup_backup(backup_path)
        raise "pbxproj file corruption detected after HotLoad Build Phase addition"
      end
      
    rescue => e
      puts "Error during HotLoad Build Phase addition: #{e.message}"
      if File.exist?(backup_path)
        FileUtils.copy(backup_path, @project_file_path)
        cleanup_backup(backup_path)
        puts "Restored pbxproj file from backup"
      end
      raise e
    end
  end

  def generate_hotload_script_phase(uuid)
    # hotload_build_phase.shの内容を直接埋め込み
    script_content = generate_inline_hotload_script
    
    <<~CONTENT.chomp
\t\t#{uuid} /* SwiftJsonUI HotLoad */ = {
\t\t\tisa = PBXShellScriptBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\tinputFileListPaths = (
\t\t\t);
\t\t\tinputPaths = (
\t\t\t);
\t\t\tname = "SwiftJsonUI HotLoad";
\t\t\toutputFileListPaths = (
\t\t\t);
\t\t\toutputPaths = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t\tshellPath = /bin/bash;
\t\t\tshellScript = "#{script_content}";
\t\t};
    CONTENT
  end

  def generate_inline_hotload_script
    # hotload_build_phase.shの主要な処理を直接記述
    <<~SCRIPT.strip.gsub(/\n/, '\\n').gsub(/"/, '\\"')
# SwiftJsonUI HotLoad Setup
# DEBUGビルドでのみ実行
if [ "${CONFIGURATION}" != "Debug" ]; then
    echo "Release build detected. Skipping HotLoad setup."
    exit 0
fi

echo "=== SwiftJsonUI HotLoad Setup ==="
echo "BUILD CONFIGURATION: ${CONFIGURATION}"
echo "PROJECT_DIR: ${PROJECT_DIR}"
echo "SRCROOT: ${SRCROOT}"

# Info.plist更新は ip_monitor.sh スクリプトに任せる
echo "Info.plist update is handled by ip_monitor.sh script"

# Node.jsサーバー起動確認
check_server_running() {
    local port=8081
    lsof -ti:$port >/dev/null 2>&1
}

# Node.jsサーバー起動
start_hotload_server() {
    local hotload_server_dir="$SRCROOT/bindingTestApp/hot_loader"
    
    if [ ! -d "$hotload_server_dir" ]; then
        echo "Warning: HotLoad server directory not found: $hotload_server_dir"
        return 1
    fi
    
    cd "$hotload_server_dir"
    
    if [ ! -f "server.js" ]; then
        echo "Warning: server.js not found in HotLoad server directory"
        return 1
    fi
    
    if [ ! -d "node_modules" ]; then
        echo "Installing Node.js dependencies..."
        npm install >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "Warning: npm install failed"
            return 1
        fi
    fi
    
    if check_server_running; then
        echo "HotLoad server is already running on port 8081"
        return 0
    fi
    
    echo "Starting server.js..."
    nohup node server.js > server.log 2>&1 &
    
    for i in {1..10}; do
        if check_server_running; then
            echo "HotLoad server started successfully on port 8081"
            return 0
        fi
        sleep 0.5
    done
    
    echo "Warning: HotLoad server may not have started properly"
    return 1
}

# Node.jsが利用可能かチェック
if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    start_hotload_server
else
    echo "Warning: Node.js or npm not found. HotLoad server cannot be started."
fi

echo "=== HotLoad Setup Complete ==="
echo "HotLoad server started on port 8081"
echo "Info.plist configuration handled by ip_monitor.sh"
    SCRIPT
  end

  def setup_app_delegate_hotload
    require_relative "app_delegate_setup"
    app_delegate_setup = AppDelegateSetup.new(@project_file_path)
    app_delegate_setup.add_hotloader_functionality
  end

  def get_target_name
    # プロジェクトファイル名からターゲット名を取得
    project_name = File.basename(File.dirname(@project_file_path), ".xcodeproj")
    project_name
  end

  def generate_uuid
    # Xcodeプロジェクト用のUUID生成（24文字）
    chars = ("A".."Z").to_a + ("0".."9").to_a
    (0...24).map { chars[rand(chars.length)] }.join
  end
end

# コマンドライン実行
if __FILE__ == $0
  if ARGV.length != 1
    puts "Usage: ruby hotload_setup.rb <project_file_path>"
    puts "Example: ruby hotload_setup.rb /path/to/project.pbxproj"
    exit 1
  end

  project_file_path = ARGV[0]
  
  begin
    setup = HotLoadSetup.new(project_file_path)
    setup.setup_hotload_build_phase
  rescue => e
    puts "Error: #{e.message}"
    puts e.backtrace.join("\n")
    exit 1
  end
end