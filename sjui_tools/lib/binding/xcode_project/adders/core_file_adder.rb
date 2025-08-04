require_relative "file_adder"

class CoreFileAdder < FileAdder
  def self.add_core_file(project_manager, file_path, group_name, project_content = nil)
    puts "Adding core file to Xcode project: #{File.basename(file_path)}"
    
    # project_contentが渡されていない場合は、safe_add_filesを使用
    if project_content.nil?
      safe_add_files(project_manager) do |content|
        add_core_file_to_project(project_manager, content, file_path, group_name)
      end
    else
      # project_contentが渡されている場合は直接処理
      add_core_file_to_project(project_manager, project_content, file_path, group_name)
    end
  end
  
  def self.add_core_file_to_project(project_manager, project_content, file_path, group_name)
    # ファイル情報
    file_name = File.basename(file_path)
    
    # ファイルが既にプロジェクトに含まれているかチェック
    # PBXBuildFileセクションでのパターン（正確なパターン）
    build_file_pattern = /= \{isa = PBXBuildFile;.*\/\* #{Regexp.escape(file_name)} in Sources \*\//
    file_ref_pattern = /\/\* #{Regexp.escape(file_name)} \*\/ = \{isa = PBXFileReference/
    
    # デバッグ: 各パターンのチェック結果を出力
    puts "DEBUG: Checking if #{file_name} exists in project..."
    has_build_file = project_content.match?(build_file_pattern)
    has_file_ref = project_content.match?(file_ref_pattern)
    
    puts "DEBUG: Has PBXBuildFile entry: #{has_build_file}"
    puts "DEBUG: Has PBXFileReference entry: #{has_file_ref}"
    
    if has_build_file
      puts "#{file_name} is already in the project's build phases"
      if !has_file_ref
        puts "WARNING: #{file_name} is in build phases but has no file reference!"
      end
      puts "DEBUG: Skipping #{file_name} as it's already in PBXBuildFile"
      return
    end
    
    # Sources Build Phaseでのチェックも追加
    sources_pattern = /#{Regexp.escape(file_name)} in Sources \*\/,/
    if project_content.match?(sources_pattern)
      puts "WARNING: #{file_name} is already in Sources build phase but not in PBXBuildFile!"
      puts "DEBUG: Will proceed to add PBXBuildFile entry"
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
    insert_line = find_or_create_pbx_build_file_section_end(project_content)
    puts "DEBUG: PBXBuildFile section end at line: #{insert_line}"
    
    if insert_line.nil?
      puts "ERROR: Could not find or create PBXBuildFile section!"
      return
    end
    
    lines = project_content.lines
    build_entries = build_file_uuids.map do |uuid|
      entry = "\t\t#{uuid} /* #{file_name} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_ref_uuid} /* #{file_name} */; };\n"
      puts "DEBUG: Creating PBXBuildFile entry: #{entry.strip}"
      entry
    end
    
    puts "DEBUG: Inserting #{build_entries.length} entries at line #{insert_line}"
    lines.insert(insert_line, *build_entries)
    project_content.replace(lines.join)
    puts "Added PBXBuildFile entries (#{build_file_uuids.length} targets)"
    
    # 確認のため、追加されたかチェック
    if project_content.include?("#{build_file_uuids.first} /* #{file_name} in Sources */")
      puts "DEBUG: Successfully verified PBXBuildFile entry was added"
    else
      puts "ERROR: PBXBuildFile entry was NOT added to content!"
    end
  end

  def self.add_to_group(project_manager, project_content, file_ref_uuid, file_name, group_name)
    # グループのUUIDを検索
    group_uuid = find_group_uuid_by_name(project_content, group_name)
    
    if group_uuid.nil?
      # UI/BaseグループがCore内にある場合の特別処理
      if group_name == "UI" || group_name == "Base"
        core_uuid = find_group_uuid_by_name(project_content, "Core")
        if core_uuid
          # Core内のUI/Baseを探す
          group_uuid = find_subgroup_in_parent(project_content, core_uuid, group_name)
        end
      end
      
      if group_uuid.nil?
        puts "Warning: Group '#{group_name}' not found. File will be added but not in a specific group."
        return
      end
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
  
  def self.find_subgroup_in_parent(project_content, parent_uuid, subgroup_name)
    lines = project_content.lines
    in_parent_group = false
    in_children = false
    
    lines.each_with_index do |line, index|
      # 親グループの開始を検出
      if line.include?("#{parent_uuid} /* ") && line.include?(" */ = {")
        in_parent_group = true
      elsif in_parent_group && line.strip == "};"
        in_parent_group = false
        in_children = false
      elsif in_parent_group && line.include?("children = (")
        in_children = true
      elsif in_parent_group && in_children
        # childrenセクション内でサブグループを探す
        if line.match(/([A-F0-9]{24}) \/\* #{Regexp.escape(subgroup_name)} \*\//)
          return $1
        end
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