require_relative "file_adder"

class JsonAdder < FileAdder
  def self.add_json_file(project_manager, json_file_path, group_name = nil)
    puts "Adding JSON file to Xcode project..."
    
    # Layoutsグループが必要で存在しない場合は作成
    if group_name == "Layouts"
      project_content = File.read(project_manager.project_file_path)
      if !project_content.include?("/* Layouts */ = {")
        puts "Layouts group not found, creating it..."
        project_manager.add_folder_group("Layouts", "Layouts")
      end
    end
    
    safe_add_files(project_manager) do |project_content|
      # ファイル情報
      file_name = File.basename(json_file_path)
      
      # グループからの相対パスを計算
      relative_path = calculate_group_relative_path(json_file_path, group_name, project_manager)
      
      # ファイルが既にプロジェクトに含まれているかチェック
      build_file_pattern = /\/\* #{Regexp.escape(file_name)} in Resources \*\//
      file_ref_pattern = /\/\* #{Regexp.escape(file_name)} \*\/ = \{isa = PBXFileReference/
      if project_content.match?(build_file_pattern) || project_content.match?(file_ref_pattern)
        puts "#{file_name} is already in the project"
        return
      end
      
      # テスト用ターゲットを除外してビルドフェーズを検出
      resources_targets = count_non_test_build_phases(project_manager, project_content, "PBXResourcesBuildPhase")
      puts "Detected #{resources_targets} non-test resource targets for JSON file"
      
      # UUIDの生成
      file_ref_uuid = project_manager.generate_uuid
      resource_uuids = resources_targets.times.map { project_manager.generate_uuid }
      
      # 1. PBXFileReferenceを追加
      # サブディレクトリがある場合でも、相対パスを保持する
      file_path_for_reference = relative_path
      add_pbx_file_reference(project_content, file_ref_uuid, file_name, file_path_for_reference)
      
      # 2. PBXBuildFileを追加（複数ターゲット対応）
      add_pbx_build_files(project_content, resource_uuids, file_ref_uuid, file_name)
      
      # 3. グループに追加（指定されている場合）
      if group_name
        add_to_group(project_manager, project_content, file_ref_uuid, file_name, group_name, relative_path)
      end
      
      # 4. Resources Build Phaseに追加
      add_to_resources_build_phases(project_content, resource_uuids, file_name)
      
      puts "✅ Added '#{file_name}' to Xcode project successfully"
    end
  end

  private
  
  def self.calculate_group_relative_path(json_file_path, group_name, project_manager)
    return File.basename(json_file_path) unless group_name
    
    # プロジェクトルートを取得
    project_root = File.dirname(File.dirname(project_manager.project_file_path))
    
    # グループフォルダへのパスを構築
    group_folder_path = File.join(project_root, group_name)
    
    # JSONファイルのフルパスからグループフォルダの相対パスを計算
    require 'pathname'
    begin
      file_pathname = Pathname.new(json_file_path)
      group_pathname = Pathname.new(group_folder_path)
      
      # グループフォルダからの相対パス
      relative = file_pathname.relative_path_from(group_pathname).to_s
      
      # 相対パスが..で始まる場合は、ファイルがグループ外にあることを意味する
      if relative.start_with?('../')
        # プロジェクトルートからの相対パスを取得
        file_path_from_project = file_pathname.relative_path_from(Pathname.new(project_root)).to_s
        # グループ名/で始まる場合は、グループ名を除去
        # bindingTestApp/Layouts/... のようなパスも考慮
        if file_path_from_project.include?("/#{group_name}/")
          # /Layouts/ より後の部分を取得
          file_path_from_project.split("/#{group_name}/", 2).last
        elsif file_path_from_project.start_with?("#{group_name}/")
          file_path_from_project.sub("#{group_name}/", '')
        else
          File.basename(json_file_path)
        end
      else
        # 相対パスをそのまま返す（サブディレクトリ構造を保持）
        relative
      end
    rescue => e
      # 相対パス計算に失敗した場合はファイル名のみ
      File.basename(json_file_path)
    end
  end

  def self.add_pbx_file_reference(project_content, file_ref_uuid, file_name, relative_path = nil)
    insert_line = find_pbx_file_reference_section_end(project_content)
    return unless insert_line
    
    lines = project_content.lines
    # グループ内のファイルは、そのグループからの相対パスのみを使用
    # relative_pathがある場合はそれを使用、なければファイル名のみ
    path = relative_path || file_name
    
    # pathにエスケープが必要な文字が含まれているかチェック
    if path.include?(' ') || path.include?('"')
      path = path.gsub('"', '\\"')  # ダブルクォートをエスケープ
      new_entry = "\t\t#{file_ref_uuid} /* #{file_name} */ = {isa = PBXFileReference; lastKnownFileType = text.json; path = \"#{path}\"; sourceTree = \"<group>\"; };\n"
    else
      new_entry = "\t\t#{file_ref_uuid} /* #{file_name} */ = {isa = PBXFileReference; lastKnownFileType = text.json; path = #{path}; sourceTree = \"<group>\"; };\n"
    end
    
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

  def self.add_to_group(project_manager, project_content, file_ref_uuid, file_name, group_name, relative_path = nil)
    # グループのUUIDを検索
    group_uuid = find_group_uuid_by_name(project_content, group_name)
    return unless group_uuid
    
    # サブディレクトリがある場合の処理
    if relative_path && relative_path.include?('/')
      # サブディレクトリがある場合、サブグループを作成または検索
      subdirs = File.dirname(relative_path).split('/')
      current_group_uuid = group_uuid
      current_group_name = group_name
      
      subdirs.each do |subdir|
        # サブグループを探す、なければ作成
        subgroup_uuid = find_or_create_subgroup(project_manager, project_content, current_group_uuid, current_group_name, subdir)
        current_group_uuid = subgroup_uuid
        current_group_name = subdir
      end
      
      group_uuid = current_group_uuid
    end
    
    # グループの定義を探す
    insert_line = nil
    project_content.each_line.with_index do |line, index|
      if line.include?("#{group_uuid} /* ") && line.include?(" */ = {")
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
    puts "Added to group hierarchy"
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
  
  def self.find_or_create_subgroup(project_manager, project_content, parent_group_uuid, parent_group_name, subgroup_name)
    # 親グループ内でサブグループを探す
    lines = project_content.lines
    in_parent_group = false
    in_children = false
    
    lines.each_with_index do |line, index|
      if line.include?("#{parent_group_uuid} /* ")
        in_parent_group = true
      elsif in_parent_group && line.strip == "};"
        in_parent_group = false
        in_children = false
      elsif in_parent_group && line.include?("children = (")
        in_children = true
      elsif in_parent_group && in_children
        if line.match(/([A-F0-9]{24}) \/\* #{Regexp.escape(subgroup_name)} \*\//)
          return $1
        end
      end
    end
    
    # サブグループが見つからない場合は作成
    subgroup_uuid = project_manager.generate_uuid
    puts "Creating subgroup '#{subgroup_name}' with UUID #{subgroup_uuid} under parent #{parent_group_uuid}"
    create_subgroup(project_content, parent_group_uuid, subgroup_uuid, subgroup_name)
    subgroup_uuid
  end
  
  def self.create_subgroup(project_content, parent_group_uuid, subgroup_uuid, subgroup_name)
    lines = project_content.lines
    
    # 1. PBXGroupセクションにサブグループを追加
    pbx_group_section_end = nil
    lines.each_with_index do |line, index|
      if line.strip == "/* End PBXGroup section */"
        pbx_group_section_end = index
        break
      end
    end
    
    if pbx_group_section_end
      new_entry = "\t\t#{subgroup_uuid} /* #{subgroup_name} */ = {\n"
      new_entry += "\t\t\tisa = PBXGroup;\n"
      new_entry += "\t\t\tchildren = (\n"
      new_entry += "\t\t\t);\n"
      new_entry += "\t\t\tname = #{subgroup_name};\n"
      new_entry += "\t\t\tpath = #{subgroup_name};\n"
      new_entry += "\t\t\tsourceTree = \"<group>\";\n"
      new_entry += "\t\t};\n"
      lines.insert(pbx_group_section_end, new_entry)
    end
    
    # 2. 親グループのchildrenに追加
    in_parent_group = false
    in_children = false
    children_end = nil
    
    lines.each_with_index do |line, index|
      if line.include?("#{parent_group_uuid} /* ")
        in_parent_group = true
      elsif in_parent_group && line.strip == "};"
        break
      elsif in_parent_group && line.include?("children = (")
        in_children = true
      elsif in_parent_group && in_children && (line.strip == ");" || line.include?(");"))
        children_end = index
        break
      end
    end
    
    if children_end
      puts "Adding subgroup to parent at line #{children_end}"
      # 空のchildren配列の場合と既存要素がある場合を処理
      if lines[children_end - 1].strip.empty? || lines[children_end - 1].include?("children = (")
        # 空の場合
        lines.insert(children_end, "\t\t\t\t#{subgroup_uuid} /* #{subgroup_name} */,\n")
      else
        # 既存要素がある場合 - 閉じカッコの前に新しいエントリを挿入
        lines.insert(children_end, "\t\t\t\t#{subgroup_uuid} /* #{subgroup_name} */,\n")
      end
    else
      puts "WARNING: Could not find children end for parent group #{parent_group_uuid}"
    end
    
    project_content.replace(lines.join)
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