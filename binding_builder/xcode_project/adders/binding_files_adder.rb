require_relative "file_adder"

class BindingFilesAdder < FileAdder
  def self.add_binding_files(project_manager, file_names)
    return if file_names.empty?
    
    puts "Adding #{file_names.length} binding files to Xcode project in batch..."
    
    safe_add_files(project_manager) do |project_content|
      # 既に存在するファイルをフィルタリング（PBXBuildFileセクションでチェック）
      new_file_names = file_names.reject do |file_name|
        # PBXBuildFileセクションに "FileName.swift in Sources" が存在するかチェック
        build_file_pattern = /\/\* #{Regexp.escape(file_name)} in Sources \*\//
        if project_content.match?(build_file_pattern)
          puts "#{file_name} is already in the project's build phases, skipping..."
          true
        else
          puts "#{file_name} is NOT in build phases, will be added..."
          false
        end
      end
      
      if new_file_names.empty?
        puts "All files are already in the project"
        return
      end
      
      puts "Adding #{new_file_names.length} new binding files (#{file_names.length - new_file_names.length} already exist)"
      
      # テスト用ターゲットを除外してビルドフェーズを検出
      sources_targets = count_non_test_build_phases(project_manager, project_content, "PBXSourcesBuildPhase")
      puts "Detected #{sources_targets} non-test source targets for binding files"
      
      # 各ファイルのUUIDを生成
      file_data = new_file_names.map do |file_name|
        build_uuids = sources_targets.times.map { project_manager.generate_uuid }
        {
          name: file_name,
          file_ref_uuid: project_manager.generate_uuid,
          build_file_uuids: build_uuids
        }
      end
      
      # ファイル名でソート（アルファベット順）
      file_data.sort_by! { |data| data[:name] }
      
      # 既存のBindingファイルを取得してソート済みリストを作成
      existing_bindings = []
      project_content.each_line do |line|
        if line.include?("Binding.swift") && line.include?("PBXFileReference") && line.include?("lastKnownFileType = sourcecode.swift")
          match = line.match(/\/\* (\w+Binding\.swift) \*\//)
          existing_bindings << match[1] if match
        end
      end
      existing_bindings.sort!
      
      # 新しいファイルと既存ファイルをマージしたソート済みリストを作成
      all_bindings = (existing_bindings + new_file_names).sort
      
      # 1. PBXBuildFile セクションに追加
      add_to_pbx_build_file_section(project_content, file_data, all_bindings)
      
      # 2. PBXFileReference セクションに追加  
      add_to_pbx_file_reference_section(project_content, file_data, all_bindings)
      
      # 3. Bindingsグループに追加
      add_to_bindings_group(project_manager, project_content, file_data, all_bindings)
      
      # 4. Sourcesビルドフェーズに追加
      add_to_sources_build_phases(project_content, file_data, all_bindings)
      
      puts "Successfully added #{new_file_names.length} binding files to Xcode project"
    end
  end

  private

  def self.add_to_pbx_build_file_section(project_content, file_data, all_bindings)
    # PBXBuildFileセクションの終わりを探す
    insert_line = find_pbx_build_file_section_end(project_content)
    return unless insert_line
    
    lines = project_content.lines
    file_data.each do |data|
      build_entries = data[:build_file_uuids].map do |uuid|
        "\t\t#{uuid} /* #{data[:name]} in Sources */ = {isa = PBXBuildFile; fileRef = #{data[:file_ref_uuid]} /* #{data[:name]} */; };\n"
      end
      lines.insert(insert_line, *build_entries)
      insert_line += build_entries.length
    end
    project_content.replace(lines.join)
    puts "Added PBXBuildFile entries for #{file_data.length} files"
  end

  def self.add_to_pbx_file_reference_section(project_content, file_data, all_bindings)
    # PBXFileReferenceセクションの終わりを探す
    insert_line = find_pbx_file_reference_section_end(project_content)
    return unless insert_line
    
    lines = project_content.lines
    file_data.each do |data|
      file_ref_entry = "\t\t#{data[:file_ref_uuid]} /* #{data[:name]} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = #{data[:name]}; sourceTree = \"<group>\"; };\n"
      lines.insert(insert_line, file_ref_entry)
      insert_line += 1
    end
    project_content.replace(lines.join)
    puts "Added PBXFileReference entries for #{file_data.length} files"
  end

  def self.add_to_bindings_group(project_manager, project_content, file_data, all_bindings)
    # BindingsグループのUUIDを動的に検出
    bindings_group_uuid = project_manager.find_bindings_group_uuid(project_content)
    return unless bindings_group_uuid
    
    # Bindingsグループの定義を探す（参照ではなく）
    insert_line = nil
    project_content.each_line.with_index do |line, index|
      if line.include?("#{bindings_group_uuid} /* Bindings */ = {") 
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
    file_data.each do |data|
      group_entry = "\t\t\t\t#{data[:file_ref_uuid]} /* #{data[:name]} */,\n"
      lines.insert(insert_line, group_entry)
      insert_line += 1
    end
    project_content.replace(lines.join)
    puts "Added to Bindings group (UUID: #{bindings_group_uuid}) for #{file_data.length} files"
  end

  def self.add_to_sources_build_phases(project_content, file_data, all_bindings)
    # テスト用以外のSources build phasesを探す
    sources_insert_lines = find_non_test_build_phase_insert_lines(project_content, "PBXSourcesBuildPhase")
    
    # 最初のファイルのbuild_file_uuidsの長さでターゲット数を判断
    target_count = file_data.first[:build_file_uuids].length
    puts "DEBUG: sources_insert_lines: #{sources_insert_lines.inspect}"
    puts "DEBUG: target_count from file_data: #{target_count}"
    return unless sources_insert_lines.length >= target_count
    
    lines = project_content.lines
    # 後ろから追加して行番号がずれないようにする
    file_data.reverse.each do |data|
      # 各ターゲットに追加
      data[:build_file_uuids].each_with_index.reverse_each do |uuid, index|
        sources_entry = "\t\t\t\t#{uuid} /* #{data[:name]} in Sources */,\n"
        lines.insert(sources_insert_lines[index], sources_entry)
      end
      # 次のファイルのために行番号を調整
      sources_insert_lines = sources_insert_lines.map { |line| line + target_count }
    end
    project_content.replace(lines.join)
    puts "Added to Sources build phases for #{file_data.length} files (#{target_count} targets each)"
  end
end