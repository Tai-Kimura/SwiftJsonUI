#!/usr/bin/env ruby

class LibrarySetupHelper
  def self.find_target_section(content, project_name)
    # Find the main app target section
    target_match = nil
    in_target = false
    target_start = nil
    
    content.each_line.with_index do |line, index|
      # Look for target definition
      if line.match(/([A-F0-9]{24}) \/\* #{Regexp.escape(project_name)} \*\/ = \{/)
        target_start = index
        in_target = true
      elsif in_target && line.include?("isa = PBXNativeTarget")
        # Confirmed it's a native target
        target_match = {
          start_index: target_start,
          uuid: content.lines[target_start].match(/([A-F0-9]{24})/)[1]
        }
      elsif in_target && line.strip == "};"
        in_target = false
        break if target_match
      end
    end
    
    target_match
  end

  def self.find_project_section(content)
    # Find the PBXProject section
    project_match = nil
    in_project = false
    project_start = nil
    
    content.each_line.with_index do |line, index|
      if line.include?("isa = PBXProject;")
        # Back up to find the start of this section
        (index-1).downto(0) do |i|
          if content.lines[i].match(/([A-F0-9]{24}) \/\* Project object \*\/ = \{/)
            project_start = i
            project_match = {
              start_index: project_start,
              uuid: content.lines[project_start].match(/([A-F0-9]{24})/)[1]
            }
            break
          end
        end
        break
      end
    end
    
    project_match
  end

  def self.insert_package_references_in_project(content, package_refs_list)
    project_info = find_project_section(content)
    return content unless project_info
    
    lines = content.lines
    insert_index = nil
    
    # Find where to insert packageReferences
    (project_info[:start_index]...(project_info[:start_index] + 50)).each do |i|
      line = lines[i]
      next unless line
      
      # Look for a good insertion point
      if line.include?("mainGroup =")
        # Insert after mainGroup
        insert_index = i + 1
        break
      elsif line.include?("buildConfigurationList =")
        # Or before buildConfigurationList
        insert_index = i
        break
      end
    end
    
    if insert_index
      indent = "\t\t\t"
      lines.insert(insert_index, "#{indent}packageReferences = (\n")
      package_refs_list.split("\n").each_with_index do |ref, idx|
        lines.insert(insert_index + 1 + idx, "#{ref}\n")
      end
      lines.insert(insert_index + 1 + package_refs_list.split("\n").length, "#{indent});\n")
    end
    
    lines.join
  end

  def self.insert_package_product_dependencies_in_target(content, project_name, package_deps_list)
    target_info = find_target_section(content, project_name)
    return content unless target_info
    
    lines = content.lines
    insert_index = nil
    
    # Find where to insert packageProductDependencies
    (target_info[:start_index]...(target_info[:start_index] + 50)).each do |i|
      line = lines[i]
      next unless line
      
      # Look for a good insertion point
      if line.include?("productName =")
        # Insert after productName
        insert_index = i + 1
        break
      elsif line.include?("dependencies =")
        # Or before dependencies
        insert_index = i
        break
      end
    end
    
    if insert_index
      indent = "\t\t\t"
      lines.insert(insert_index, "#{indent}packageProductDependencies = (\n")
      package_deps_list.split("\n").each_with_index do |dep, idx|
        lines.insert(insert_index + 1 + idx, "#{dep}\n")
      end
      lines.insert(insert_index + 1 + package_deps_list.split("\n").length, "#{indent});\n")
    end
    
    lines.join
  end
end