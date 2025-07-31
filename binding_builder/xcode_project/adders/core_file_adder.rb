require_relative "file_adder"

class CoreFileAdder < FileAdder
  def self.add_core_file(project_manager, file_path, group_name)
    puts "Adding core file to Xcode project: #{File.basename(file_path)}"
    
    safe_add_files(project_manager) do |project_content|
      # ファイル情報
      file_name = File.basename(file_path)
      
      # ファイルが既にプロジェクトに含まれているかチェック
      build_file_pattern = /\/\* #{Regexp.escape(file_name)} in Sources \*\//
      if project_content.match?(build_file_pattern)
        puts "#{file_name} is already in the project"
        return
      end
      
      # テスト用ターゲットを除外してビルドフェーズを検出
      sources_targets = count_non_test_build_phases(project_manager, project_content, "PBXSourcesBuildPhase")
      puts "Detected #{sources_targets} non-test source targets"
      
      # 必要なUUIDを生成
      file_ref_uuid = project_manager.generate_uuid
      build_file_uuids = sources_targets.times.map { project_manager.generate_uuid }
      
      # 1. PBXFileReferenceを追加
      add_pbx_file_reference(project_content, file_ref_uuid, file_name)
      
      # 2. PBXBuildFileを追加（複数ターゲット対応）
      add_pbx_build_files(project_content, build_file_uuids, file_ref_uuid, file_name)
      
      # 3. グループに追加
      add_to_group(project_manager, project_content, file_ref_uuid, file_name, group_name)
      
      # 4. Sources Build Phaseに追加
      add_to_sources_build_phases(project_content, build_file_uuids, file_name)
      
      puts "✅ Added '#{file_name}' to Xcode project successfully"
    end
  end

  private

  def self.add_pbx_file_reference(project_content, file_ref_uuid, file_name)
    insert_line = find_pbx_file_reference_section_end(project_content)
    return unless insert_line
    
    lines = project_content.lines
    new_entry = "\t\t#{file_ref_uuid} /* #{file_name} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = #{file_name}; sourceTree = \"<group>\"; };\n"
    lines.insert(insert_line, new_entry)
    project_content.replace(lines.join)
  end

  def self.add_pbx_build_files(project_content, build_file_uuids, file_ref_uuid, file_name)
    insert_line = find_pbx_build_file_section_end(project_content)
    return unless insert_line
    
    lines = project_content.lines
    build_entries = build_file_uuids.map do |uuid|
      "\t\t#{uuid} /* #{file_name} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_ref_uuid} /* #{file_name} */; };\n"
    end
    lines.insert(insert_line, *build_entries)
    project_content.replace(lines.join)
    puts "Added PBXBuildFile entries (#{build_file_uuids.length} targets)"
  end

  def self.add_to_group(project_manager, project_content, file_ref_uuid, file_name, group_name)
    # グループのUUIDを検索
    group_uuid = find_group_uuid_by_name(project_content, group_name)
    
    if group_uuid.nil?
      puts "Warning: Group '#{group_name}' not found. File will be added but not in a specific group."
      return
    end
    
    # グループの定義を探す
    insert_line = nil
    project_content.each_line.with_index do |line, index|
      if line.include?("#{group_uuid} /* #{group_name} */ = {")
        lines = project_content.lines
        (index+1..index+10).each do |i|
          if lines[i] && lines[i].include?("children = (")
            # 次の行をチェックして挿入位置を決定
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
    nil
  end

  def self.add_to_sources_build_phases(project_content, build_file_uuids, file_name)
    # テスト用以外のSources build phasesを探す
    sources_insert_lines = find_non_test_build_phase_insert_lines(project_content, "PBXSourcesBuildPhase")
    
    return unless sources_insert_lines.length >= build_file_uuids.length
    
    lines = project_content.lines
    # 後ろから追加して行番号がずれないようにする
    build_file_uuids.each_with_index.reverse_each do |uuid, index|
      sources_entry = "\t\t\t\t#{uuid} /* #{file_name} in Sources */,\n"
      lines.insert(sources_insert_lines[index], sources_entry)
    end
    project_content.replace(lines.join)
    puts "Added to Sources build phases (#{build_file_uuids.length} targets)"
  end
end