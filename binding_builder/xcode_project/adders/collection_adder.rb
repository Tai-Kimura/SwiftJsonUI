require_relative "file_adder"
require "pathname"

class CollectionAdder < FileAdder
  def self.add_collection_cell_file(project_manager, file_path, view_folder_name)
    puts "Adding collection cell to Xcode project..."
    
    safe_add_files(project_manager) do |project_content|
      # ファイル情報
      file_name = File.basename(file_path)
      
      # ファイルが既にプロジェクトに含まれているかチェック
      build_file_pattern = /\/\* #{Regexp.escape(file_name)} in Sources \*\//
      if project_content.match?(build_file_pattern)
        puts "#{file_name} is already in the project's build phases"
        return
      end
      
      # テスト用ターゲットを除外してビルドフェーズを検出
      sources_targets = count_non_test_build_phases(project_manager, project_content, "PBXSourcesBuildPhase")
      puts "Detected #{sources_targets} non-test source targets for collection cell"
      
      # UUIDの生成（複数ターゲット対応）
      file_ref_uuid = project_manager.generate_uuid
      build_file_uuids = sources_targets.times.map { project_manager.generate_uuid }
      
      # source_directoryを使用して相対パスを計算
      project_root = File.dirname(File.dirname(project_manager.project_file_path))
      source_base = project_manager.source_directory.empty? ? project_root : File.join(project_root, project_manager.source_directory)
      relative_path = Pathname.new(file_path).relative_path_from(Pathname.new(source_base)).to_s
      
      # 1. PBXFileReferenceを追加
      add_pbx_file_reference(project_content, file_ref_uuid, file_name)
      
      # 2. PBXBuildFileを追加（複数ターゲット対応）
      add_pbx_build_files(project_content, build_file_uuids, file_ref_uuid, file_name)
      
      # 3. Collectionグループに追加
      add_to_collection_group(project_manager, project_content, file_ref_uuid, file_name, view_folder_name)
      
      # 4. Sources Build Phaseに追加（複数ターゲット対応）
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
    insert_line = find_or_create_pbx_build_file_section_end(project_content)
    return unless insert_line
    
    lines = project_content.lines
    build_entries = build_file_uuids.map do |uuid|
      "\t\t#{uuid} /* #{file_name} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_ref_uuid} /* #{file_name} */; };\n"
    end
    lines.insert(insert_line, *build_entries)
    project_content.replace(lines.join)
    puts "Added PBXBuildFile entries (#{build_file_uuids.length} targets)"
  end

  def self.add_to_collection_group(project_manager, project_content, file_ref_uuid, file_name, view_folder_name)
    # Viewフォルダグループを探す
    view_folder_group_uuid = find_view_folder_group_uuid(project_content, view_folder_name)
    
    if view_folder_group_uuid.nil?
      puts "ERROR: View folder '#{view_folder_name}' not found in Xcode project"
      puts "Please ensure the view was created properly with 'sjui g view #{view_folder_name.downcase}'"
      return
    end
    
    # Collectionグループを探す（なければ作成）
    collection_group_uuid = find_collection_group_in_view_folder(project_content, view_folder_group_uuid)
    
    if collection_group_uuid.nil?
      # Collectionグループを作成
      collection_group_uuid = project_manager.generate_uuid
      add_collection_group_to_view_folder(project_manager, project_content, collection_group_uuid, view_folder_group_uuid)
    end
    
    # ファイルをCollectionグループに追加
    add_file_to_collection_group(project_content, collection_group_uuid, file_ref_uuid, file_name)
  end

  def self.find_view_folder_group_uuid(project_content, view_folder_name)
    # プロジェクトファイル全体でViewフォルダグループを探す
    lines = project_content.lines
    
    lines.each_with_index do |line, index|
      # 形式1: UUID /* Name */ = {isa = PBXGroup; children = ( （1行形式）
      if line.match(/([A-F0-9]{24}) \/\* #{Regexp.escape(view_folder_name)} \*\/ = \{isa = PBXGroup;/)
        puts "Found View folder group (inline format): #{$1} for #{view_folder_name}"
        return $1
      # 形式2: UUID /* Name */ = { で始まり、isa = PBXGroupを探す
      elsif line.match(/([A-F0-9]{24}) \/\* #{Regexp.escape(view_folder_name)} \*\/ = \{/)
        uuid = $1
        # 現在の行自体にisa = PBXGroupが含まれているかチェック
        if line.include?("isa = PBXGroup")
          puts "Found View folder group (same line): #{uuid} for #{view_folder_name}"
          return uuid
        end
        # 次の数行でisa = PBXGroupがあるか確認
        (1..5).each do |offset|
          next_line = lines[index + offset]
          if next_line && next_line.include?("isa = PBXGroup")
            puts "Found View folder group (multi-line): #{uuid} for #{view_folder_name}"
            return uuid
          end
        end
      end
    end
    puts "Warning: Could not find View folder group '#{view_folder_name}' in project file"
    nil
  end

  def self.find_collection_group_in_view_folder(project_content, view_folder_group_uuid)
    lines = project_content.lines
    in_view_folder_group = false
    children_section = false
    
    lines.each_with_index do |line, index|
      if line.include?("#{view_folder_group_uuid} /* ") && line.include?(" */ = {")
        in_view_folder_group = true
        puts "DEBUG: Found view folder group section"
      elsif in_view_folder_group && line.include?("children = (")
        children_section = true
        puts "DEBUG: Found children section"
      elsif in_view_folder_group && children_section && line.strip == ");"
        children_section = false
      elsif in_view_folder_group && line.strip == "};"
        in_view_folder_group = false
      elsif in_view_folder_group && children_section && line.match(/([A-F0-9]{24}) \/\* Collection \*\//)
        puts "DEBUG: Found Collection group: #{$1}"
        return $1
      end
    end
    puts "DEBUG: No Collection group found in view folder"
    nil
  end

  def self.add_collection_group_to_view_folder(project_manager, project_content, collection_group_uuid, view_folder_group_uuid)
    # まずPBXGroupセクションにCollectionグループを追加
    add_pbx_group_entry(project_content, collection_group_uuid, "Collection", "Collection")
    
    # ViewFolderグループのchildrenにCollectionグループを追加
    lines = project_content.lines
    in_view_folder_group = false
    children_section_found = false
    
    lines.each_with_index do |line, index|
      if line.include?("#{view_folder_group_uuid} /* ") && line.include?(" */ = {")
        in_view_folder_group = true
      elsif in_view_folder_group && line.include?("children = (")
        children_section_found = true
        # 空のchildren配列の場合、次の行に追加
        if lines[index + 1] && lines[index + 1].strip == ");"
          new_reference = "\t\t\t\t#{collection_group_uuid} /* Collection */,\n"
          lines.insert(index + 1, new_reference)
          project_content.replace(lines.join)
          puts "Added Collection group to View folder (empty children)"
          break
        end
      elsif in_view_folder_group && children_section_found && line.strip == ");"
        # childrenセクションの終わりを見つけたので、その前に追加
        new_reference = "\t\t\t\t#{collection_group_uuid} /* Collection */,\n"
        lines.insert(index, new_reference)
        project_content.replace(lines.join)
        puts "Added Collection group to View folder"
        break
      end
    end
  end

  def self.add_pbx_group_entry(project_content, group_uuid, group_name, relative_path)
    # PBXGroupセクションの最後を見つけて、新しいエントリを追加
    lines = project_content.lines
    pbx_group_section_end = nil
    in_pbx_group = false
    
    lines.each_with_index do |line, index|
      if line.include?("/* Begin PBXGroup section */")
        in_pbx_group = true
      elsif line.include?("/* End PBXGroup section */")
        pbx_group_section_end = index
        break
      end
    end
    
    if pbx_group_section_end
      new_entry = "\t\t#{group_uuid} /* #{group_name} */ = {\n"
      new_entry += "\t\t\tisa = PBXGroup;\n"
      new_entry += "\t\t\tchildren = (\n"
      new_entry += "\t\t\t);\n"
      new_entry += "\t\t\tpath = #{relative_path};\n"
      new_entry += "\t\t\tsourceTree = \"<group>\";\n"
      new_entry += "\t\t};\n"
      
      lines.insert(pbx_group_section_end, new_entry)
      project_content.replace(lines.join)
      puts "Added PBXGroup entry for Collection"
    else
      puts "ERROR: Could not find PBXGroup section"
    end
  end

  def self.add_file_to_collection_group(project_content, collection_group_uuid, file_ref_uuid, file_name)
    lines = project_content.lines
    in_collection_group = false
    children_section_found = false
    
    lines.each_with_index do |line, index|
      if line.include?("#{collection_group_uuid} /* Collection */ = {")
        in_collection_group = true
        puts "DEBUG: Found Collection group to add file to"
      elsif in_collection_group && line.include?("children = (")
        children_section_found = true
        # 空のchildren配列の場合、次の行に追加
        if lines[index + 1] && lines[index + 1].strip == ");"
          new_reference = "\t\t\t\t#{file_ref_uuid} /* #{file_name} */,\n"
          lines.insert(index + 1, new_reference)
          project_content.replace(lines.join)
          puts "Added #{file_name} to Collection group (empty children)"
          break
        end
      elsif in_collection_group && children_section_found && line.strip == ");"
        # childrenセクションの終わりを見つけたので、その前に追加
        new_reference = "\t\t\t\t#{file_ref_uuid} /* #{file_name} */,\n"
        lines.insert(index, new_reference)
        project_content.replace(lines.join)
        puts "Added #{file_name} to Collection group"
        break
      end
    end
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