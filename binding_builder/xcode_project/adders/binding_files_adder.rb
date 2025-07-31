require "fileutils"

module BindingFilesAdder
  def self.add_binding_files(project_manager, file_names)
    return unless File.exist?(project_manager.project_file_path)
    return if file_names.empty?
    
    puts "Adding #{file_names.length} binding files to Xcode project in batch..."
    
    # プロジェクトファイルをバックアップ
    backup_path = project_manager.project_file_path + ".backup"
    FileUtils.copy(project_manager.project_file_path, backup_path)
    
    begin
      # プロジェクトファイルを読み取り
      project_content = File.read(project_manager.project_file_path)
      
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
      
      # プロジェクトファイルを書き戻し
      File.write(project_manager.project_file_path, project_content)
      puts "Successfully added #{new_file_names.length} binding files to Xcode project"
      
      # バックアップファイルを削除
      File.delete(backup_path) if File.exist?(backup_path)
      
    rescue => e
      puts "Error adding binding files to Xcode project: #{e.message}"
      puts e.backtrace.first(3)
      # エラー時は元のファイルを復元
      if File.exist?(backup_path)
        FileUtils.copy(backup_path, project_manager.project_file_path)
        File.delete(backup_path)
        puts "Restored original project file"
      end
    end
  end

  private

  def self.count_non_test_build_phases(project_manager, project_content, phase_type)
    # ターゲットとビルドフェーズを取得
    target_build_phases = get_target_build_phases(project_content, phase_type)
    puts "DEBUG: Found #{target_build_phases.length} total build phases for #{phase_type}"
    
    # .appターゲットのビルドフェーズをカウント
    count = 0
    target_build_phases.each do |target_uuid, build_phase_uuid|
      puts "DEBUG: Checking target #{target_uuid}"
      if is_app_target?(project_content, target_uuid)
        puts "DEBUG: Target #{target_uuid} is an app target"
        count += 1
      else
        puts "DEBUG: Target #{target_uuid} is NOT an app target"
      end
    end
    puts "DEBUG: Found #{count} app targets"
    count
  end

  def self.find_non_test_build_phase_insert_lines(project_content, phase_type)
    target_build_phases = get_target_build_phases(project_content, phase_type)
    insert_lines = []
    
    puts "DEBUG: find_non_test_build_phase_insert_lines called with #{target_build_phases.length} phases"
    
    target_build_phases.each do |target_uuid, build_phase_uuid|
      if is_app_target?(project_content, target_uuid)
        puts "DEBUG: Looking for build phase #{build_phase_uuid} in Sources section"
        # ビルドフェーズのfiles = (行を見つける
        found_build_phase = false
        project_content.each_line.with_index do |line, index|
          # PBXSourcesBuildPhaseセクション内の定義を探す（= {で終わる行）
          if line.include?("#{build_phase_uuid} /* Sources */ = {")
            puts "DEBUG: Found build phase definition at line #{index}"
            found_build_phase = true
            # 次の数行でfiles = (を探す
            (index+1..index+10).each do |i|
              if project_content.lines[i] && project_content.lines[i].include?("files = (")
                puts "DEBUG: Found 'files = (' at line #{i}"
                insert_lines << i + 1
                break
              end
            end
            break
          end
        end
        puts "DEBUG: Build phase found: #{found_build_phase}" unless found_build_phase
      end
    end
    puts "DEBUG: Total insert lines found: #{insert_lines.length}"
    insert_lines
  end

  def self.get_target_build_phases(project_content, phase_type)
    target_build_phases = []
    current_target = nil
    current_target_name = nil
    in_target = false
    in_build_phases = false
    
    project_content.each_line do |line|
      # PBXNativeTargetの開始を検出
      if line.match(/([A-F0-9]{24}) \/\* (.+?) \*\/ = \{/)
        uuid = $1
        name = $2
        # 次の行でisa = PBXNativeTargetかチェックするため一時保存
        current_target = uuid
        current_target_name = name
        in_target = false
      elsif current_target && line.include?("isa = PBXNativeTarget")
        # 前の行で見つけたUUIDが実際にPBXNativeTargetだった
        in_target = true
        puts "DEBUG: Found PBXNativeTarget: #{current_target_name} (#{current_target})"
      elsif in_target && line.include?("buildPhases = (")
        # buildPhasesセクション内でSourcesを探す
        in_build_phases = true
      elsif in_target && in_build_phases && line.match(/([A-F0-9]{24}) \/\* Sources \*\/,/)
        build_phase_uuid = $1
        puts "DEBUG: Found Sources build phase for target #{current_target}: #{build_phase_uuid}"
        target_build_phases << [current_target, build_phase_uuid]
      elsif in_build_phases && line.strip == ");"
        # buildPhasesセクションの終了
        in_build_phases = false
      elsif line.strip == "};" && in_target
        # ターゲットセクションの終了
        in_target = false
        in_build_phases = false
        current_target = nil
        current_target_name = nil
      end
    end
    puts "DEBUG: Total target_build_phases found: #{target_build_phases.length}"
    target_build_phases
  end

  def self.is_app_target?(project_content, target_uuid)
    # ターゲットのproductReferenceを取得
    product_ref_uuid = get_target_product_reference(project_content, target_uuid)
    puts "DEBUG: Target #{target_uuid} has productReference: #{product_ref_uuid}"
    return false unless product_ref_uuid
    
    # productReferenceが.appかどうかチェック
    result = is_app_product?(project_content, product_ref_uuid)
    puts "DEBUG: is_app_product returned: #{result}"
    result
  end

  def self.get_target_product_reference(project_content, target_uuid)
    in_target_section = false
    found_target_header = false
    
    project_content.each_line do |line|
      # ターゲットの開始を検出
      if line.include?("#{target_uuid} /*") && line.include?("*/ = {")
        found_target_header = true
        puts "DEBUG: Found target header for #{target_uuid}"
      elsif found_target_header && line.include?("isa = PBXNativeTarget")
        in_target_section = true
        puts "DEBUG: Confirmed PBXNativeTarget for #{target_uuid}"
      elsif in_target_section && line.include?("productReference = ")
        puts "DEBUG: Found productReference line: #{line.strip}"
        if line.match(/productReference = ([A-F0-9]{24}) \/\*/)
          puts "DEBUG: Extracted productReference UUID: #{$1}"
          return $1
        end
      elsif in_target_section && line.strip == "};"
        puts "DEBUG: End of target section, no productReference found"
        break
      end
    end
    nil
  end

  def self.is_app_product?(project_content, product_ref_uuid)
    project_content.each_line do |line|
      if line.include?(product_ref_uuid) && line.include?("isa = PBXFileReference")
        # .app で終わるかチェック
        puts "DEBUG: Found product reference line: #{line.strip}"
        result = line.include?(".app")
        puts "DEBUG: Line contains .app: #{result}"
        return result
      end
    end
    puts "DEBUG: Product reference #{product_ref_uuid} not found"
    false
  end

  def self.add_to_pbx_build_file_section(project_content, file_data, all_bindings)
    # PBXBuildFileセクションの終わりを探す
    insert_line = nil
    project_content.each_line.with_index do |line, index|
      if line.include?("/* End PBXBuildFile section */")
        insert_line = index
        break
      end
    end
    
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
    insert_line = nil
    project_content.each_line.with_index do |line, index|
      if line.include?("/* End PBXFileReference section */")
        insert_line = index
        break
      end
    end
    
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
    puts "DEBUG: file_data.first[:build_file_uuids]: #{file_data.first[:build_file_uuids].inspect}"
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