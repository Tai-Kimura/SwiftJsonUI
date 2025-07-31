require "fileutils"
require "pathname"
require_relative "adders/view_controller_adder"
require_relative "adders/binding_files_adder"
require_relative "adders/collection_adder"
require_relative "adders/json_adder"
require_relative "pbxproj_manager"

class XcodeProjectManager < PbxprojManager
  attr_reader :project_file_path, :source_directory

  def initialize(project_file_path)
    super(project_file_path)
  end

  def add_binding_files(file_names)
    BindingFilesAdder.add_binding_files(self, file_names)
  end

  def add_view_controller_file(file_name, folder_name, json_file_name = nil)
    ViewControllerAdder.add_view_controller_file(self, file_name, folder_name, json_file_name)
  end

  def add_collection_cell_file(file_path, view_folder_name)
    CollectionAdder.add_collection_cell_file(self, file_path, view_folder_name)
  end

  def add_json_file(json_file_path, group_name = nil)
    JsonAdder.add_json_file(self, json_file_path, group_name)
  end

  def add_folder_group(group_name, relative_path)
    return unless File.exist?(@project_file_path)
    puts "Adding folder group '#{group_name}'..."
    
    # バックアップ作成
    backup_path = create_backup(@project_file_path)
    
    begin
      project_content = File.read(@project_file_path)
      
      # すでにグループが存在するかチェック
      if find_group_uuid_by_name(project_content, group_name)
        puts "  Group '#{group_name}' already exists in Xcode project"
        cleanup_backup(backup_path)
        return
      end
      
      # 新しいグループのUUIDを生成
      group_uuid = generate_uuid
      
      # PBXGroupエントリを追加
      add_pbx_group_entry(project_content, group_uuid, group_name, relative_path)
      
      # メインプロジェクトグループに追加
      add_to_main_project_group(project_content, group_uuid, group_name)
      
      # ファイルに書き込み
      File.write(@project_file_path, project_content)
      
      # 整合性をチェック
      if validate_pbxproj(@project_file_path)
        puts "✅ Added '#{group_name}' group to Xcode project successfully"
        cleanup_backup(backup_path)
      else
        puts "❌ pbxproj file validation failed, rolling back..."
        FileUtils.copy(backup_path, @project_file_path)
        cleanup_backup(backup_path)
        raise "pbxproj file corruption detected after adding folder group"
      end
      
    rescue => e
      puts "Error during folder group addition: #{e.message}"
      if File.exist?(backup_path)
        FileUtils.copy(backup_path, @project_file_path)
        cleanup_backup(backup_path)
        puts "Restored pbxproj file from backup"
      end
      raise e
    end
  end

  # Public methods for modules to access
  def generate_uuid
    chars = ('A'..'F').to_a + ('0'..'9').to_a
    24.times.map { chars.sample }.join
  end

  def count_build_phases(project_content, phase_type)
    count = 0
    project_content.each_line do |line|
      count += 1 if line.include?("isa = #{phase_type}")
    end
    count
  end

  def find_bindings_group_uuid(project_content, group_name = "Bindings")
    project_content.each_line do |line|
      if line.match(/([A-F0-9]{24}) \/\* #{group_name} \*\/ = \{/)
        return $1
      end
    end
    nil
  end

  def find_view_group_uuid(project_content)
    # First try traditional PBXGroup format
    project_content.each_line do |line|
      if line.match(/([A-F0-9]{24}) \/\* View \*\/ = \{/)
        return $1
      end
    end
    
    # If not found, look for View in the newer format or create a virtual reference
    # For newer Xcode projects, we might need to handle this differently
    # Return a special marker that indicates we should use the root group
    "USE_ROOT_GROUP"
  end

  def find_group_uuid_by_name(project_content, group_name)
    project_content.each_line do |line|
      if line.match(/([A-F0-9]{24}) \/\* #{Regexp.escape(group_name)} \*\/ = \{/)
        return $1
      end
    end
    nil
  end

  def add_pbx_group_entry(project_content, group_uuid, group_name, relative_path)
    # PBXGroupセクションの最後を見つけて、新しいエントリを追加
    lines = project_content.lines
    pbx_group_section_end = nil
    
    lines.each_with_index do |line, index|
      if line.strip == "/* End PBXGroup section */"
        pbx_group_section_end = index
        break
      end
    end
    
    if pbx_group_section_end
      new_entry = "\t\t#{group_uuid} /* #{group_name} */ = {\n"
      new_entry += "\t\t\tisa = PBXGroup;\n"
      new_entry += "\t\t\tchildren = (\n"
      new_entry += "\t\t\t);\n"
      new_entry += "\t\t\tname = #{group_name};\n"
      new_entry += "\t\t\tpath = #{relative_path};\n"
      new_entry += "\t\t\tsourceTree = \"<group>\";\n"
      new_entry += "\t\t};\n"
      
      lines.insert(pbx_group_section_end, new_entry)
      project_content.replace(lines.join)
    end
  end

  def add_to_main_project_group(project_content, group_uuid, group_name)
    # メインプロジェクトグループを見つけて、新しいグループを追加
    lines = project_content.lines
    
    lines.each_with_index do |line, index|
      # メインプロジェクトグループを探す
      if line.match(/([A-F0-9]{24}) \/\* #{@project_name} \*\/ = \{/)
        # このグループの children セクションを見つける
        children_start = nil
        children_end = nil
        
        (index + 1...lines.length).each do |i|
          if lines[i].include?("children = (") && children_start.nil?
            children_start = i + 1
          elsif lines[i].strip == ");" && children_start && children_end.nil?
            children_end = i
            break
          end
        end
        
        if children_start && children_end
          # 新しいグループ参照を追加
          new_reference = "\t\t\t\t#{group_uuid} /* #{group_name} */,\n"
          lines.insert(children_end, new_reference)
          project_content.replace(lines.join)
          break
        end
      end
    end
  end

  private

  def find_collection_group_in_view_folder(project_content, view_folder_group_uuid)
    lines = project_content.lines
    in_view_folder_group = false
    
    lines.each_with_index do |line, index|
      if line.include?("#{view_folder_group_uuid} /* ") && line.include?(" */ = {")
        in_view_folder_group = true
      elsif in_view_folder_group && line.strip == "};"
        in_view_folder_group = false
      elsif in_view_folder_group && line.match(/([A-F0-9]{24}) \/\* Collection \*\//)
        return $1
      end
    end
    nil
  end

  def add_collection_group_to_view_folder(project_content, collection_group_uuid, view_folder_group_uuid, group_name)
    # まずPBXGroupセクションにCollectionグループを追加
    add_pbx_group_entry(project_content, collection_group_uuid, group_name, group_name)
    
    # ViewFolderグループのchildrenにCollectionグループを追加
    lines = project_content.lines
    in_view_folder_group = false
    children_section_found = false
    
    lines.each_with_index do |line, index|
      if line.include?("#{view_folder_group_uuid} /* ") && line.include?(" */ = {")
        in_view_folder_group = true
      elsif in_view_folder_group && line.include?("children = (")
        children_section_found = true
      elsif in_view_folder_group && children_section_found && line.strip == ");"
        # childrenセクションの終わりを見つけたので、その前に追加
        new_reference = "\t\t\t\t#{collection_group_uuid} /* #{group_name} */,\n"
        lines.insert(index, new_reference)
        project_content.replace(lines.join)
        break
      end
    end
  end

end