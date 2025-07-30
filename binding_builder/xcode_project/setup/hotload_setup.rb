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
    # sjui hotload listenを実行するシンプルなスクリプト
    <<~SCRIPT.strip.gsub(/\n/, '\\n').gsub(/"/, '\\"')
# SwiftJsonUI HotLoad Setup
# DEBUGビルドでのみ実行
if [ "${CONFIGURATION}" != "Debug" ]; then
    echo "Release build detected. Skipping HotLoad setup."
    exit 0
fi

echo "=== SwiftJsonUI HotLoad Setup ==="

# プロジェクトファイルのパスからbinding_builderディレクトリを探す
# @project_file_pathはproject.pbxprojファイルなので、.xcodeprojの親ディレクトリを取得
PROJECT_DIR="#{File.dirname(File.dirname(@project_file_path))}"
echo "Starting search from project directory: ${PROJECT_DIR}"

# findコマンドでbinding_builderディレクトリを探す（sjuiファイルが存在するものを優先）
BINDING_BUILDER_DIR=""
for dir in $(find "${PROJECT_DIR}" -maxdepth 5 -name "binding_builder" -type d 2>/dev/null | grep -v node_modules); do
    if [ -f "${dir}/sjui" ]; then
        BINDING_BUILDER_DIR="${dir}"
        break
    fi
done

# sjuiが見つからない場合は、最初に見つかったbinding_builderを使用
if [ -z "${BINDING_BUILDER_DIR}" ]; then
    BINDING_BUILDER_DIR=$(find "${PROJECT_DIR}" -maxdepth 5 -name "binding_builder" -type d 2>/dev/null | grep -v node_modules | head -1)
fi

# 見つからない場合は親ディレクトリも探す
if [ -z "${BINDING_BUILDER_DIR}" ]; then
    PARENT_DIR="#{File.dirname(File.dirname(File.dirname(@project_file_path)))}"
    echo "Searching in parent directory: ${PARENT_DIR}"
    for dir in $(find "${PARENT_DIR}" -maxdepth 5 -name "binding_builder" -type d 2>/dev/null | grep -v node_modules); do
        if [ -f "${dir}/sjui" ]; then
            BINDING_BUILDER_DIR="${dir}"
            break
        fi
    done
fi

# それでも見つからない場合は、より広範囲に探す
if [ -z "${BINDING_BUILDER_DIR}" ]; then
    # XcodeのPROJECT_DIRやSRCROOTも使ってみる
    if [ -n "${PROJECT_DIR}" ] && [ -d "${PROJECT_DIR}" ]; then
        echo "Searching using Xcode PROJECT_DIR: ${PROJECT_DIR}"
        for dir in $(find "${PROJECT_DIR}" -maxdepth 5 -name "binding_builder" -type d 2>/dev/null | grep -v node_modules); do
            if [ -f "${dir}/sjui" ]; then
                BINDING_BUILDER_DIR="${dir}"
                break
            fi
        done
    fi
    
    if [ -z "${BINDING_BUILDER_DIR}" ] && [ -n "${SRCROOT}" ] && [ -d "${SRCROOT}" ]; then
        echo "Searching using Xcode SRCROOT: ${SRCROOT}"
        for dir in $(find "${SRCROOT}" -maxdepth 5 -name "binding_builder" -type d 2>/dev/null | grep -v node_modules); do
            if [ -f "${dir}/sjui" ]; then
                BINDING_BUILDER_DIR="${dir}"
                break
            fi
        done
    fi
fi

if [ -z "${BINDING_BUILDER_DIR}" ]; then
    echo "Warning: binding_builder directory not found"
    echo "Searched from: ${PROJECT_DIR}"
    echo "PROJECT_DIR env: ${PROJECT_DIR}"
    echo "SRCROOT env: ${SRCROOT}"
    exit 0
fi

echo "Found binding_builder at: ${BINDING_BUILDER_DIR}"

# config.jsonからsource_directoryを取得（必要に応じて）
SOURCE_DIR=""
CONFIG_FILE="${BINDING_BUILDER_DIR}/config.json"

if [ -f "${CONFIG_FILE}" ]; then
    # Read config.json with proper permissions handling
    if [ -r "${CONFIG_FILE}" ]; then
        SOURCE_DIR=$(grep -o '"source_directory"[[:space:]]*:[[:space:]]*"[^"]*"' "${CONFIG_FILE}" 2>/dev/null | sed 's/.*"source_directory"[[:space:]]*:[[:space:]]*"\\([^"]*\\)".*/\\1/' 2>/dev/null || echo "")
        if [ -n "${SOURCE_DIR}" ]; then
            echo "Found source_directory: '${SOURCE_DIR}'"
        fi
    else
        echo "Warning: Cannot read config.json (permission denied)"
    fi
fi

# sjuiコマンドのパスを設定
BINDING_BUILDER_PATH="${BINDING_BUILDER_DIR}/sjui"

# binding_builderディレクトリの内容を確認（デバッグ用）
echo "Checking binding_builder directory contents:"
ls -la "${BINDING_BUILDER_DIR}" | head -10

# sjuiコマンドが存在するか確認
if [ ! -f "${BINDING_BUILDER_PATH}" ]; then
    echo "Warning: sjui command not found at ${BINDING_BUILDER_PATH}"
    # 実行権限がない可能性もチェック
    if [ -e "${BINDING_BUILDER_PATH}" ]; then
        echo "File exists but may not have execute permissions"
        ls -la "${BINDING_BUILDER_PATH}"
    fi
    exit 0
fi

# sjui hotload listenを実行
echo "Starting HotLoad development environment..."
"${BINDING_BUILDER_PATH}" hotload listen

echo "=== HotLoad Setup Complete ==="
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