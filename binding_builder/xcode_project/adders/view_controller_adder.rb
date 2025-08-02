require "json"
require_relative "file_adder"
require_relative "../../project_finder"

class ViewControllerAdder < FileAdder
  def self.add_view_controller_file(project_manager, file_name, folder_name, json_file_name = nil)
    puts "Adding #{file_name} (ViewController) to Xcode project..."
    
    safe_add_files(project_manager) do |project_content|
      # Layoutsグループの存在を確認
      if project_content.include?("/* Layouts */ = {")
        puts "DEBUG: Layouts group exists before ViewControllerAdder processing"
      else
        puts "WARNING: Layouts group NOT found before ViewControllerAdder processing"
      end
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
      
      # JSONファイルはLayoutsグループに残すため、UUIDは生成しない
      json_file_ref_uuid = nil
      json_resource_uuids = []
      
      puts "Generated UUIDs: file_ref=#{file_ref_uuid}, builds=[#{build_file_uuids.join(', ')}], folder=#{folder_uuid}"
      puts "JSON UUIDs: file_ref=#{json_file_ref_uuid}, resources=[#{json_resource_uuids.join(', ')}]" if json_file_name
      
      # ViewControllerファイル用の処理
      add_view_controller_to_sections(project_manager, project_content, file_name, folder_name, file_ref_uuid, build_file_uuids, folder_uuid, json_file_name, json_file_ref_uuid, json_resource_uuids)
      
      # 処理後のLayoutsグループの存在を確認
      if project_content.include?("/* Layouts */ = {")
        puts "DEBUG: Layouts group still exists after ViewControllerAdder processing"
      else
        puts "ERROR: Layouts group DISAPPEARED after ViewControllerAdder processing!"
      end
      
      puts "Successfully added #{file_name} to Xcode project"
    end
  end

  private

  def self.detect_project_name(project_file_path)
    ProjectFinder.detect_project_name(project_file_path)
  end

  def self.add_view_controller_to_sections(project_manager, project_content, file_name, folder_name, file_ref_uuid, build_file_uuids, folder_uuid, json_file_name, json_file_ref_uuid, json_resource_uuids)
    # 1. PBXBuildFile セクションに追加
    insert_line = find_or_create_pbx_build_file_section_end(project_content)
    
    if insert_line
      lines = project_content.lines
      build_entries = []
      
      # Sourcesエントリを追加
      build_file_uuids.each do |uuid|
        build_entries << "\t\t#{uuid} /* #{file_name} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_ref_uuid} /* #{file_name} */; };\n"
      end
      
      # JSONファイルのビルドエントリは追加しない（Layoutsグループに残す）
      
      lines.insert(insert_line, *build_entries)
      project_content.replace(lines.join)
      puts "Added PBXBuildFile entries for ViewController (#{build_file_uuids.length} targets)#{json_file_name ? " and JSON (#{json_resource_uuids.length} targets)" : ''}"
    end
    
    # 2. PBXFileReference セクションに追加（フォルダとファイル）
    insert_line = find_pbx_file_reference_section_end(project_content)
    
    if insert_line
      lines = project_content.lines
      file_entries = [
        "\t\t#{file_ref_uuid} /* #{file_name} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = #{file_name}; sourceTree = \"<group>\"; };\n"
      ]
      
      # JSONファイルのPBXFileReferenceは追加しない（Layoutsグループに残す）
      
      # フォルダエントリ（ViewControllerのみ含める、JSONはLayoutsグループに残す）
      children_list = "#{file_ref_uuid} /* #{file_name} */,"
      
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
    
    # JSONファイルは既にLayoutsグループからResourcesに追加されているため、ここでは追加しない
  end
end