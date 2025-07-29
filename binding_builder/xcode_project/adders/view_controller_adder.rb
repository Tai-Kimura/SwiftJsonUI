require "fileutils"
require "json"
require_relative "../../project_finder"

module ViewControllerAdder
  def self.add_view_controller_file(project_manager, file_name, folder_name, json_file_name = nil)
    return unless File.exist?(project_manager.project_file_path)
    
    puts "Adding #{file_name} (ViewController) to Xcode project..."
    
    # プロジェクトファイルをバックアップ
    backup_path = project_manager.project_file_path + ".backup"
    FileUtils.copy(project_manager.project_file_path, backup_path)
    
    begin
      # プロジェクトファイルを読み取り
      project_content = File.read(project_manager.project_file_path)
      
      # ファイルが既にプロジェクトに含まれているかチェック
      if project_content.include?(file_name)
        puts "#{file_name} is already in the project"
        return
      end
      
      # テスト用ターゲットを除外してビルドフェーズを検出
      non_test_sources = count_non_test_build_phases(project_manager, project_content, "PBXSourcesBuildPhase")
      non_test_resources = count_non_test_build_phases(project_manager, project_content, "PBXResourcesBuildPhase")
      sources_targets = non_test_sources
      resources_targets = non_test_resources
      
      puts "Detected #{sources_targets} non-test source targets and #{resources_targets} non-test resource targets"
      
      # 必要なUUIDを動的に生成
      file_ref_uuid = project_manager.generate_uuid
      folder_uuid = project_manager.generate_uuid
      build_file_uuids = sources_targets.times.map { project_manager.generate_uuid }
      
      json_file_ref_uuid = json_file_name ? project_manager.generate_uuid : nil
      json_resource_uuids = json_file_name ? resources_targets.times.map { project_manager.generate_uuid } : []
      
      puts "Generated UUIDs: file_ref=#{file_ref_uuid}, builds=[#{build_file_uuids.join(', ')}], folder=#{folder_uuid}"
      puts "JSON UUIDs: file_ref=#{json_file_ref_uuid}, resources=[#{json_resource_uuids.join(', ')}]" if json_file_name
      
      # ViewControllerファイル用の処理
      add_view_controller_to_sections(project_manager, project_content, file_name, folder_name, file_ref_uuid, build_file_uuids, folder_uuid, json_file_name, json_file_ref_uuid, json_resource_uuids)
      
      # プロジェクトファイルを書き戻し
      File.write(project_manager.project_file_path, project_content)
      puts "Successfully added #{file_name} to Xcode project"
      
      # バックアップファイルを削除
      File.delete(backup_path) if File.exist?(backup_path)
      
    rescue => e
      puts "Error adding #{file_name} to Xcode project: #{e.message}"
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
    
    # .appターゲットのビルドフェーズをカウント
    count = 0
    target_build_phases.each do |target_uuid, build_phase_uuid|
      if is_app_target?(project_content, target_uuid)
        count += 1
      end
    end
    count
  end

  def self.find_non_test_build_phase_insert_lines(project_content, phase_type)
    target_build_phases = get_target_build_phases(project_content, phase_type)
    insert_lines = []
    
    target_build_phases.each do |target_uuid, build_phase_uuid|
      if is_app_target?(project_content, target_uuid)
        # ビルドフェーズのfiles = (行を見つける
        project_content.each_line.with_index do |line, index|
          if line.include?("#{build_phase_uuid} /*") && line.include?("isa = #{phase_type}")
            (index+1..index+10).each do |i|
              if project_content.lines[i] && project_content.lines[i].include?("files = (")
                insert_lines << i + 1
                break
              end
            end
            break
          end
        end
      end
    end
    insert_lines
  end


  def self.get_target_build_phases(project_content, phase_type)
    target_build_phases = []
    current_target = nil
    
    project_content.each_line do |line|
      if line.match(/([A-F0-9]{24}) \/\* (.+?) \*\/ = \{/) && line.include?("isa = PBXNativeTarget")
        current_target = $1
      elsif current_target && line.match(/([A-F0-9]{24}) \/\* .+ \*\/,/) && line.include?("#{phase_type}")
        build_phase_uuid = $1
        target_build_phases << [current_target, build_phase_uuid]
      end
    end
    target_build_phases
  end

  def self.get_target_name_by_uuid(project_content, target_uuid)
    project_content.each_line do |line|
      if line.include?(target_uuid) && line.include?("isa = PBXNativeTarget")
        if line.match(/\/\* (.+?) \*\//)
          return $1
        end
      end
    end
    nil
  end

  def self.is_app_target?(project_content, target_uuid)
    # ターゲットのproductReferenceを取得
    product_ref_uuid = get_target_product_reference(project_content, target_uuid)
    return false unless product_ref_uuid
    
    # productReferenceが.appかどうかチェック
    is_app_product?(project_content, product_ref_uuid)
  end

  def self.get_target_product_reference(project_content, target_uuid)
    in_target_section = false
    
    project_content.each_line do |line|
      if line.include?(target_uuid) && line.include?("isa = PBXNativeTarget")
        in_target_section = true
      elsif in_target_section && line.include?("productReference = ")
        if line.match(/productReference = ([A-F0-9]{24})/)
          return $1
        end
      elsif in_target_section && line.strip == "};"
        break
      end
    end
    nil
  end

  def self.is_app_product?(project_content, product_ref_uuid)
    project_content.each_line do |line|
      if line.include?(product_ref_uuid) && line.include?("isa = PBXFileReference")
        # .app で終わるかチェック
        return line.include?(".app")
      end
    end
    false
  end


  def self.detect_project_name(project_file_path)
    ProjectFinder.detect_project_name(project_file_path)
  end

  def self.add_view_controller_to_sections(project_manager, project_content, file_name, folder_name, file_ref_uuid, build_file_uuids, folder_uuid, json_file_name, json_file_ref_uuid, json_resource_uuids)
    # 1. PBXBuildFile セクションに追加
    insert_line = nil
    project_content.each_line.with_index do |line, index|
      if line.include?("/* End PBXBuildFile section */")
        insert_line = index
        break
      end
    end
    
    if insert_line
      lines = project_content.lines
      build_entries = []
      
      # Sourcesエントリを追加
      build_file_uuids.each do |uuid|
        build_entries << "\t\t#{uuid} /* #{file_name} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_ref_uuid} /* #{file_name} */; };\n"
      end
      
      # JSONファイルがある場合はリソースエントリも追加
      if json_file_name
        json_resource_uuids.each do |uuid|
          build_entries << "\t\t#{uuid} /* #{json_file_name} in Resources */ = {isa = PBXBuildFile; fileRef = #{json_file_ref_uuid} /* #{json_file_name} */; };\n"
        end
      end
      
      lines.insert(insert_line, *build_entries)
      project_content.replace(lines.join)
      puts "Added PBXBuildFile entries for ViewController (#{build_file_uuids.length} targets)#{json_file_name ? " and JSON (#{json_resource_uuids.length} targets)" : ''}"
    end
    
    # 2. PBXFileReference セクションに追加（フォルダとファイル）
    insert_line = nil
    project_content.each_line.with_index do |line, index|
      if line.include?("/* End PBXFileReference section */")
        insert_line = index
        break
      end
    end
    
    if insert_line
      lines = project_content.lines
      file_entries = [
        "\t\t#{file_ref_uuid} /* #{file_name} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = #{file_name}; sourceTree = \"<group>\"; };\n"
      ]
      
      # JSONファイルがある場合は追加
      if json_file_name
        # プロジェクト名を動的に取得
        project_name = detect_project_name(project_manager.project_file_path)
        file_entries << "\t\t#{json_file_ref_uuid} /* #{json_file_name} */ = {isa = PBXFileReference; lastKnownFileType = text.json; name = #{json_file_name}; path = #{project_name}/Layouts/#{json_file_name}; sourceTree = SOURCE_ROOT; };\n"
      end
      
      # フォルダエントリ（JSONファイルがある場合は両方含める）
      children_list = "#{file_ref_uuid} /* #{file_name} */,"
      if json_file_name
        children_list += "\n\t\t\t\t#{json_file_ref_uuid} /* #{json_file_name} */,"
      end
      
      file_entries << "\t\t#{folder_uuid} /* #{folder_name} */ = {isa = PBXGroup; children = (\n\t\t\t\t#{children_list}\n\t\t\t); path = #{folder_name}; sourceTree = \"<group>\"; };\n"
      
      lines.insert(insert_line, *file_entries)
      project_content.replace(lines.join)
      puts "Added PBXFileReference entries for ViewController, folder#{json_file_name ? ', and JSON' : ''}"
    end
    
    # 3. Viewグループに追加
    view_group_uuid = project_manager.find_view_group_uuid(project_content)
    if view_group_uuid
      insert_line = nil
      project_content.each_line.with_index do |line, index|
        if line.include?("#{view_group_uuid} /* View */ = {")
          lines = project_content.lines
          (index+1..index+10).each do |i|
            if lines[i] && lines[i].include?("children = (")
              insert_line = i + 1
              break
            end
          end
          break
        end
      end
      
      if insert_line
        lines = project_content.lines
        group_entry = "\t\t\t\t#{folder_uuid} /* #{folder_name} */,\n"
        lines.insert(insert_line, group_entry)
        project_content.replace(lines.join)
        puts "Added to View group"
      end
    end
    
    # 4. テスト用以外のSources build phasesに追加
    sources_insert_lines = find_non_test_build_phase_insert_lines(project_content, "PBXSourcesBuildPhase")
    
    if sources_insert_lines.length >= build_file_uuids.length
      lines = project_content.lines
      # 後ろから追加して行番号がずれないようにする
      build_file_uuids.each_with_index.reverse_each do |uuid, index|
        sources_entry = "\t\t\t\t#{uuid} /* #{file_name} in Sources */,\n"
        lines.insert(sources_insert_lines[index], sources_entry)
      end
      project_content.replace(lines.join)
      puts "Added to Sources build phases (#{build_file_uuids.length} targets)"
    end
    
    # 5. JSONファイルがある場合はテスト用以外のResources build phasesに追加
    if json_file_name && !json_resource_uuids.empty?
      resources_insert_lines = find_non_test_build_phase_insert_lines(project_content, "PBXResourcesBuildPhase")
      
      if resources_insert_lines.length >= json_resource_uuids.length
        lines = project_content.lines
        # 後ろから追加して行番号がずれないようにする
        json_resource_uuids.each_with_index.reverse_each do |uuid, index|
          resources_entry = "\t\t\t\t#{uuid} /* #{json_file_name} in Resources */,\n"
          lines.insert(resources_insert_lines[index], resources_entry)
        end
        project_content.replace(lines.join)
        puts "Added JSON to Resources build phases (#{json_resource_uuids.length} targets)"
      end
    end
  end
end