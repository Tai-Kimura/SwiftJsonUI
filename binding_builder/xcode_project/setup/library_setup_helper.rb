#!/usr/bin/env ruby

class LibrarySetupHelper
  def self.find_target_section(content, project_name)
    # Find the main app target section
    # For Xcode 16 format, the target might be defined more compactly
    
    # Try multi-line format first
    target_match = content.match(/([A-F0-9]{24}) \/\* #{Regexp.escape(project_name)} \*\/ = \{[^}]*?isa = PBXNativeTarget[^}]*?productType = "com\.apple\.product-type\.application"[^}]*?\}/m)
    
    if target_match
      # Find the start index
      start_index = content.index(target_match[0])
      lines_before = content[0...start_index].count("\n")
      
      return {
        start_index: lines_before,
        uuid: target_match[1],
        content: target_match[0]
      }
    end
    
    # Fallback to line-by-line search
    target_match = nil
    in_target = false
    target_start = nil
    is_app_target = false
    
    content.each_line.with_index do |line, index|
      # Look for target definition
      if line.match(/([A-F0-9]{24}) \/\* #{Regexp.escape(project_name)} \*\/ = \{/)
        target_start = index
        in_target = true
      elsif in_target && line.include?("isa = PBXNativeTarget")
        # Check if it's an app target
        is_app_target = true
      elsif in_target && line.include?('productType = "com.apple.product-type.application"')
        is_app_target = true
      elsif in_target && line.strip == "};"
        if is_app_target
          target_match = {
            start_index: target_start,
            uuid: content.lines[target_start].match(/([A-F0-9]{24})/)[1]
          }
        end
        in_target = false
        is_app_target = false
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
    
    # If we have the full content, work with that
    if target_info[:content]
      # Find a good insertion point within the target content
      target_content = target_info[:content]
      
      # Look for insertion points
      if target_content.match(/productName = [^;]+;/)
        # Insert after productName
        new_target_content = target_content.gsub(
          /(productName = [^;]+;)/,
          "\\1\n\t\t\tpackageProductDependencies = (\n#{package_deps_list}\n\t\t\t);"
        )
      elsif target_content.match(/name = #{Regexp.escape(project_name)};/)
        # Insert after name
        new_target_content = target_content.gsub(
          /(name = #{Regexp.escape(project_name)};)/,
          "\\1\n\t\t\tpackageProductDependencies = (\n#{package_deps_list}\n\t\t\t);"
        )
      else
        # Insert before the closing brace
        new_target_content = target_content.gsub(
          /(\n\s*\};)$/,
          "\n\t\t\tpackageProductDependencies = (\n#{package_deps_list}\n\t\t\t);\\1"
        )
      end
      
      content = content.sub(target_info[:content], new_target_content)
    else
      # Fallback to line-by-line approach
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
      
      content = lines.join
    end
    
    content
  end
end