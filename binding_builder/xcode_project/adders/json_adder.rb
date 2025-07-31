require_relative "file_adder"
require_relative "../../project_finder"

class JsonAdder < FileAdder
  def self.add_json_file(project_manager, json_file_path, group_name = nil)
    puts "Adding JSON file to Xcode project..."
    
    safe_add_files(project_manager) do |project_content|
      # ファイル情報
      file_name = File.basename(json_file_path)
      
      # ファイルが既にプロジェクトに含まれているかチェック
      build_file_pattern = /\/\* #{Regexp.escape(file_name)} in Resources \*\//
      if project_content.match?(build_file_pattern)
        puts "#{file_name} is already in the project's resources"
        return
      end
      
      # テスト用ターゲットを除外してビルドフェーズを検出
      resources_targets = count_non_test_build_phases(project_manager, project_content, "PBXResourcesBuildPhase")
      puts "Detected #{resources_targets} non-test resource targets for JSON file"
      
      # UUIDの生成
      file_ref_uuid = project_manager.generate_uuid
      resource_uuids = resources_targets.times.map { project_manager.generate_uuid }
      
      # プロジェクト名を動的に取得（パス計算用）
      project_name = ProjectFinder.detect_project_name(project_manager.project_file_path)
      
      # 相対パスを計算
      project_root = File.dirname(File.dirname(project_manager.project_file_path))
      relative_path = calculate_relative_path(json_file_path, project_root, project_name)
      
      # 1. PBXFileReferenceを追加
      add_pbx_file_reference(project_content, file_ref_uuid, file_name, relative_path, project_name)
      
      # 2. PBXBuildFileを追加（複数ターゲット対応）
      add_pbx_build_files(project_content, resource_uuids, file_ref_uuid, file_name)
      
      # 3. グループに追加（指定されている場合）
      if group_name
        add_to_group(project_manager, project_content, file_ref_uuid, file_name, group_name)
      end
      
      # 4. Resources Build Phaseに追加
      add_to_resources_build_phases(project_content, resource_uuids, file_name)
      
      puts "✅ Added '#{file_name}' to Xcode project successfully"
    end
  end

  private

  def self.calculate_relative_path(json_file_path, project_root, project_name)
    # ファイルのフルパスからプロジェクトルートからの相対パスを計算
    require 'pathname'
    file_pathname = Pathname.new(json_file_path)
    project_pathname = Pathname.new(project_root)
    
    begin
      relative = file_pathname.relative_path_from(project_pathname).to_s
      # プロジェクト名を含むパスにする
      "#{project_name}/#{relative}"
    rescue
      # 相対パス計算に失敗した場合はファイル名だけ返す
      File.basename(json_file_path)
    end
  end

  def self.add_pbx_file_reference(project_content, file_ref_uuid, file_name, relative_path, project_name)
    insert_line = find_pbx_file_reference_section_end(project_content)
    return unless insert_line
    
    lines = project_content.lines
    # JSONファイルの場合、SOURCE_ROOTからの相対パスを使用
    new_entry = "\t\t#{file_ref_uuid} /* #{file_name} */ = {isa = PBXFileReference; lastKnownFileType = text.json; name = #{file_name}; path = #{relative_path}; sourceTree = SOURCE_ROOT; };\n"
    lines.insert(insert_line, new_entry)
    project_content.replace(lines.join)
  end

  def self.add_pbx_build_files(project_content, resource_uuids, file_ref_uuid, file_name)
    insert_line = find_pbx_build_file_section_end(project_content)
    return unless insert_line
    
    lines = project_content.lines
    build_entries = resource_uuids.map do |uuid|
      "\t\t#{uuid} /* #{file_name} in Resources */ = {isa = PBXBuildFile; fileRef = #{file_ref_uuid} /* #{file_name} */; };\n"
    end
    lines.insert(insert_line, *build_entries)
    project_content.replace(lines.join)
    puts "Added PBXBuildFile entries (#{resource_uuids.length} targets)"
  end

  def self.add_to_group(project_manager, project_content, file_ref_uuid, file_name, group_name)
    # グループのUUIDを検索
    group_uuid = find_group_uuid_by_name(project_content, group_name)
    return unless group_uuid
    
    # グループの定義を探す
    insert_line = nil
    project_content.each_line.with_index do |line, index|
      if line.include?("#{group_uuid} /* #{group_name} */ = {")
        lines = project_content.lines
        (index+1..index+10).each do |i|
          if lines[i] && lines[i].include?("children = (")
            # 空のchildrenリストの場合は、`);` を探してその前に挿入
            if lines[i+1] && lines[i+1].strip == ");"
              insert_line = i + 1
            else
              insert_line = i + 1
            end
            break
          end
        end
        break
      end
    end
    
    return unless insert_line
    
    lines = project_content.lines
    group_entry = "\t\t\t\t#{file_ref_uuid} /* #{file_name} */,\n"
    lines.insert(insert_line, group_entry)
    project_content.replace(lines.join)
    puts "Added to #{group_name} group"
  end

  def self.find_group_uuid_by_name(project_content, group_name)
    project_content.each_line do |line|
      if line.match(/([A-F0-9]{24}) \/\* #{Regexp.escape(group_name)} \*\/ = \{/)
        return $1
      end
    end
    puts "Warning: Could not find group '#{group_name}'"
    nil
  end

  def self.add_to_resources_build_phases(project_content, resource_uuids, file_name)
    # テスト用以外のResources build phasesを探す
    resources_insert_lines = find_non_test_build_phase_insert_lines(project_content, "PBXResourcesBuildPhase")
    
    return unless resources_insert_lines.length >= resource_uuids.length
    
    lines = project_content.lines
    # 後ろから追加して行番号がずれないようにする
    resource_uuids.each_with_index.reverse_each do |uuid, index|
      resources_entry = "\t\t\t\t#{uuid} /* #{file_name} in Resources */,\n"
      lines.insert(resources_insert_lines[index], resources_entry)
    end
    project_content.replace(lines.join)
    puts "Added to Resources build phases (#{resource_uuids.length} targets)"
  end
end