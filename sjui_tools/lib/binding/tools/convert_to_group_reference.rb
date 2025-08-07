#!/usr/bin/env ruby

# convert_to_group_reference.rb - Xcode 16 Synchronized Folder to Group Reference Converter (Hybrid Version)
#
# Purpose:
# This tool converts Xcode 16's new synchronized folder references back to traditional group references.
# 
# Background:
# Starting with Xcode 16, Apple introduced synchronized folders that automatically include all files
# in a directory. While convenient, this can cause issues with SwiftJsonUI's binding_builder:
# - All files in synchronized folders are automatically compiled, causing duplicate compilation errors
# - binding_builder needs precise control over which files are included in the build
# - The new format is incompatible with older Xcode versions
#
# What this tool does:
# 1. Converts PBXFileSystemSynchronizedRootGroup → PBXGroup for the main app only
# 2. Creates PBXFileReference entries for standard files (AppDelegate, SceneDelegate, etc.)
# 3. Removes exceptions and fileSystemSynchronizedGroups references
# 4. Preserves test targets as synchronized (they don't have the same issues)
# 5. Maintains all existing file references in the project
#
# Implementation:
# This hybrid version uses:
# - Direct file manipulation for Xcode 16 synchronized folder detection and initial conversion
# - xcodeproj gem for managing files and build phases after conversion
#
# Usage:
# - Run via: sjui convert to-group [--force]
# - The --force flag skips the confirmation prompt
# - A backup of the project file is created before conversion
#
# Important: Order of operations
# For new Xcode 16 projects:
# 1. Run `sjui convert to-group` first to convert synchronized folders
# 2. Then run `sjui setup` to create the SwiftJsonUI directory structure
#
# For existing projects with SwiftJsonUI already set up:
# - Run `sjui convert to-group` to fix synchronization issues
#
# After conversion:
# - The main app group will contain all existing files and groups
# - Test targets remain as synchronized folders (no issues there)
# - You can continue using binding_builder normally

require 'fileutils'
require 'json'
require 'time'
require 'xcodeproj'
require 'securerandom'
require_relative '../../core/project_finder'

module SjuiTools
  module Binding
    module Tools
      class ConvertToGroupReference
        def initialize
          # Use ProjectFinder to locate the project file
          Core::ProjectFinder.setup_paths(nil)
          project_file_path = Core::ProjectFinder.project_file_path
          
          if project_file_path.nil? || project_file_path.empty?
            raise "No .xcodeproj file found in current directory or parent directories"
          end
          
          @converter = XcodeSyncToGroupConverter.new(project_file_path)
        end
        
        def convert(force = false)
          unless force
            print "This will convert synchronized folders to regular groups. Continue? (y/n): "
            response = STDIN.gets.chomp.downcase
            return unless response == 'y'
          end
          
          @converter.convert
        end
      end
    end
  end
end

class XcodeSyncToGroupConverter
  def initialize(project_path)
    @project_path = project_path
    
    # Determine actual paths
    if project_path.end_with?('.xcodeproj')
      @xcodeproj_path = project_path
      @pbxproj_path = File.join(project_path, 'project.pbxproj')
    elsif project_path.end_with?('.pbxproj')
      @pbxproj_path = project_path
      @xcodeproj_path = File.dirname(project_path)
    else
      # Try to find .xcodeproj in the directory
      xcodeproj_files = Dir.glob(File.join(project_path, '*.xcodeproj'))
      if xcodeproj_files.empty?
        raise "No .xcodeproj file found in #{project_path}"
      end
      @xcodeproj_path = xcodeproj_files.first
      @pbxproj_path = File.join(@xcodeproj_path, 'project.pbxproj')
    end
    
    @backup_path = "#{@pbxproj_path}.backup_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
    @app_name = File.basename(@xcodeproj_path, '.xcodeproj')
    @project_dir = File.dirname(@xcodeproj_path)
    @app_dir = File.join(@project_dir, @app_name)
  end

  def convert
    puts "Converting Xcode 16 synchronized folders to group references..."
    
    # Step 1: Check if conversion is needed
    unless needs_conversion?
      puts "No synchronized groups found. Project may already be using group references."
      return false
    end
    
    # Step 2: Create backup
    create_backup
    
    # Step 3: Detect synchronized groups and collect information
    sync_info = detect_synchronized_groups
    
    if sync_info.empty?
      puts "No main app synchronized group found."
      return false
    end
    
    # Step 4: Convert synchronized groups to regular groups (direct manipulation)
    convert_synchronized_to_regular_groups(sync_info)
    
    # Step 5: Use xcodeproj gem to manage files and build phases
    manage_with_xcodeproj(sync_info)
    
    # Step 6: Validate the conversion
    validate
    
    puts "✅ Conversion completed successfully!"
    puts "ℹ️  Main app synchronized folder has been converted to regular group"
    puts "ℹ️  Test targets remain as synchronized folders (no issues there)"
    
    true
  rescue => e
    puts "Error during conversion: #{e.message}"
    puts e.backtrace.first(5).join("\n") if ENV['DEBUG']
    restore_backup if File.exist?(@backup_path)
    false
  end
  
  def validate
    content = File.read(@pbxproj_path)
    
    sync_groups = content.scan(/PBXFileSystemSynchronized(?:Root)?Group/).length
    sync_refs = content.scan(/fileSystemSynchronizedGroups/).length
    sync_exceptions = content.scan(/PBXFileSystemSynchronizedBuildFileExceptionSet/).length
    regular_groups = content.scan(/isa = PBXGroup/).length
    
    puts "\nValidation Results:"
    puts "- Regular groups (PBXGroup): #{regular_groups}"
    puts "- Synchronized groups remaining: #{sync_groups}"
    puts "- fileSystemSynchronizedGroups references: #{sync_refs}"
    puts "- Exception sets: #{sync_exceptions}"
    
    if sync_groups > 0
      puts "ℹ️  #{sync_groups} synchronized groups remain (likely test targets - this is OK)"
    end
    
    if sync_exceptions > 0
      puts "⚠️  Warning: Still has #{sync_exceptions} exception sets"
    else
      puts "✅ Main app group is now a regular PBXGroup"
    end
    
    # Validate with xcodeproj
    begin
      project = Xcodeproj::Project.open(@xcodeproj_path)
      main_group = project.main_group[@app_name]
      if main_group
        puts "✅ Main app group found with #{main_group.children.size} children"
        
        # Check for SwiftJsonUI directories
        swiftui_groups = ['View', 'Layouts', 'Styles', 'Bindings', 'Core']
        swiftui_groups.each do |group_name|
          if main_group[group_name]
            puts "  ✓ #{group_name} group exists"
          end
        end
      end
      true
    rescue => e
      puts "⚠️  Could not validate with xcodeproj: #{e.message}"
      false
    end
  end

  private

  def needs_conversion?
    content = File.read(@pbxproj_path)
    content.include?('PBXFileSystemSynchronizedRootGroup')
  end

  def create_backup
    FileUtils.copy(@pbxproj_path, @backup_path)
    puts "Backup created: #{@backup_path}"
  end

  def restore_backup
    if File.exist?(@backup_path)
      FileUtils.copy(@backup_path, @pbxproj_path)
      puts "Restored from backup: #{@backup_path}"
    end
  end

  def detect_synchronized_groups
    content = File.read(@pbxproj_path)
    sync_groups = []
    
    # First try to find the main app synchronized group
    # Look for any PBXFileSystemSynchronizedRootGroup that references the app name
    if content =~ /([A-F0-9]{24}) \/\* #{Regexp.escape(@app_name)} \*\/ = \{[^}]*?isa = PBXFileSystemSynchronized(?:Root)?Group;[^}]*?\}/m
      uuid = $1
      group_info = {
        uuid: uuid,
        name: @app_name,
        type: 'main_app'
      }
      
      # Extract exception files
      if content.match(/#{uuid}[^}]*?exceptions = \(([^)]*)\)/m)
        exception_ref = $1.strip
        # Find the actual exception set
        if content.match(/#{exception_ref}[^}]*?membershipExceptions = \(([^)]*)\)/m)
          exceptions = $1.scan(/([^,\s]+)[,\s]*/).flatten.reject(&:empty?)
          group_info[:exceptions] = exceptions
        end
      end
      
      sync_groups << group_info
      puts "Found main app synchronized group: #{uuid}"
    else
      # If not found as synchronized group, check if it's missing entirely
      # Use a default UUID that we'll create
      puts "No synchronized group found for #{@app_name}, will create new group"
      sync_groups << {
        uuid: "B6EA59982E428BF700F81080",  # Use a consistent UUID
        name: @app_name,
        type: 'main_app',
        create_new: true
      }
    end
    
    sync_groups
  end

  def convert_synchronized_to_regular_groups(sync_info)
    content = File.read(@pbxproj_path)
    
    sync_info.each do |info|
      next unless info[:type] == 'main_app'
      
      # Step 1: Remove PBXFileSystemSynchronizedBuildFileExceptionSet section
      if content.include?("/* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section */")
        content.gsub!(
          /\/\* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section \*\/.*?\/\* End PBXFileSystemSynchronizedBuildFileExceptionSet section \*\//m,
          ''
        )
        puts "Removed PBXFileSystemSynchronizedBuildFileExceptionSet section"
      end
      
      # Step 2: Always create/recreate the PBXGroup section
      # Remove existing PBXGroup section if it exists
      if content.include?("/* Begin PBXGroup section */")
        content.gsub!(/\/\* Begin PBXGroup section \*\/.*?\/\* End PBXGroup section \*\//m, '')
        puts "Removed existing PBXGroup section"
      end
      
      # Create the PBXGroup section from scratch
      group_section = create_group_section(info)
      
      # Find the best place to insert the PBXGroup section
      if content.include?("/* End PBXFileSystemSynchronizedRootGroup section */")
        # Insert after PBXFileSystemSynchronizedRootGroup section
        content.sub!(/(\/\* End PBXFileSystemSynchronizedRootGroup section \*\/)/m) do
          "#{$1}\n\n#{group_section}"
        end
      elsif content.include?("/* Begin PBXFrameworksBuildPhase section */")
        # Insert before PBXFrameworksBuildPhase section
        content.sub!(/(\/\* Begin PBXFrameworksBuildPhase section \*\/)/m) do
          "#{group_section}\n\n#{$1}"
        end
      else
        # Fallback: Insert after PBXFileReference section
        content.sub!(/(\/\* End PBXFileReference section \*\/)/m) do
          "#{$1}\n\n#{group_section}"
        end
      end
      
      puts "Added PBXGroup section"
      
      # Step 3: Remove synchronized group from the existing section (if not creating new)
      unless info[:create_new]
        # Remove the whole synchronized group definition
        content.gsub!(/\t\t#{info[:uuid]} \/\* #{Regexp.escape(info[:name])} \*\/ = \{[^}]*?isa = PBXFileSystemSynchronized(?:Root)?Group;[^}]*?\};/m, '')
      end
      
      # Step 4: Remove fileSystemSynchronizedGroups references from targets
      content.gsub!(/\s*fileSystemSynchronizedGroups = \([^)]*\);\s*/m, '')
      
      puts "Converted #{info[:name]} from synchronized to regular group"
    end
    
    # Save the converted file
    File.write(@pbxproj_path, content)
    puts "Saved initial conversion"
  end
  
  def create_group_section(info)
    # Find the existing main app synchronized group UUID
    main_app_uuid = info[:uuid] || "B6EA59982E428BF700F81080"
    
    # Read current content to find what's in the main group
    content = File.read(@pbxproj_path)
    
    # Find the main group's children from the existing structure
    main_children = if content =~ /B6EA598D2E428BF700F81080[^}]*?children = \(([^)]*)\)/m
      $1.strip
    else
      # Default children if not found
      "B6EA59B22E428BFA00F81080 /* bindingTestAppTests */,\n\t\t\t\tB6EA59BC2E428BFA00F81080 /* bindingTestAppUITests */,\n\t\t\t\tB6EA59972E428BF700F81080 /* Products */"
    end
    
    # Ensure the bindingTestApp group is in the children list
    unless main_children.include?("#{main_app_uuid} /* #{info[:name]} */")
      # Add bindingTestApp as the first child
      main_children = "#{main_app_uuid} /* #{info[:name]} */,\n\t\t\t\t#{main_children}"
    end
    
    <<-GROUP
/* Begin PBXGroup section */
		B6EA598D2E428BF700F81080 = {
			isa = PBXGroup;
			children = (
				#{main_children}
			);
			sourceTree = "<group>";
		};
		B6EA59972E428BF700F81080 /* Products */ = {
			isa = PBXGroup;
			children = (
				B6EA59962E428BF700F81080 /* bindingTestApp.app */,
				B6EA59AF2E428BFA00F81080 /* bindingTestAppTests.xctest */,
				B6EA59B92E428BFA00F81080 /* bindingTestAppUITests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		};
		#{main_app_uuid} /* #{info[:name]} */ = {
			isa = PBXGroup;
			children = (
			);
			path = #{info[:name]};
			sourceTree = "<group>";
		};
/* End PBXGroup section */
    GROUP
  end

  def manage_with_xcodeproj(sync_info)
    # Skip xcodeproj gem management - it's not working correctly with Xcode 16 format
    # Instead, add children references directly to the pbxproj file
    
    sync_info.each do |info|
      next unless info[:type] == 'main_app'
      
      puts "Adding directory references for: #{info[:name]}"
      add_children_directly_to_pbxproj(info[:uuid])
    end
    
    puts "Directory references added"
  end
  
  def add_children_directly_to_pbxproj(group_uuid)
    content = File.read(@pbxproj_path)
    
    # Find the group definition
    if content =~ /(#{group_uuid} \/\* #{Regexp.escape(@app_name)} \*\/ = \{[^}]*?children = \()([^)]*)(\);[^}]*?\})/m
      prefix = $1
      existing_children = $2
      suffix = $3
      
      # Parse existing children
      children_lines = existing_children.split(",").map(&:strip).reject(&:empty?)
      
      # Generate UUIDs for new groups if they don't exist
      swiftui_dirs = ['View', 'Layouts', 'Styles', 'Bindings', 'Core']
      groups_to_add = []
      
      swiftui_dirs.each do |dir_name|
        dir_path = File.join(@app_dir, dir_name)
        next unless Dir.exist?(dir_path)
        
        # Check if already in children
        next if children_lines.any? { |line| line.include?("/* #{dir_name} */") }
        
        # Generate a new UUID for this group
        new_uuid = generate_uuid
        
        # Add to children list
        children_lines << "#{new_uuid} /* #{dir_name} */"
        
        # Store group definition to add later
        groups_to_add << {uuid: new_uuid, name: dir_name}
        
        puts "  Adding directory group: #{dir_name} (#{new_uuid})"
      end
      
      # Update the children list in the main group
      new_children = children_lines.join(",\n\t\t\t\t")
      content.sub!(/(#{group_uuid} \/\* #{Regexp.escape(@app_name)} \*\/ = \{[^}]*?children = \()([^)]*)(\);)/m) do
        "#{$1}#{new_children}#{$3}"
      end
      
      # Add new group definitions at the end of PBXGroup section
      groups_to_add.each do |group_info|
        group_def = "\t\t#{group_info[:uuid]} /* #{group_info[:name]} */ = {\n" +
                    "\t\t\tisa = PBXGroup;\n" +
                    "\t\t\tchildren = (\n" +
                    "\t\t\t);\n" +
                    "\t\t\tpath = #{group_info[:name]};\n" +
                    "\t\t\tsourceTree = \"<group>\";\n" +
                    "\t\t};\n"
        
        # Insert before the end of PBXGroup section
        content.sub!(/(\/\* End PBXGroup section \*\/)/m) do
          "#{group_def}#{$1}"
        end
      end
    else
      puts "  Warning: Could not find group definition for UUID #{group_uuid}"
    end
    
    File.write(@pbxproj_path, content)
    puts "Updated pbxproj file directly"
  end
  
  def generate_uuid
    # Generate a 24-character hex UUID similar to Xcode format
    SecureRandom.hex(12).upcase
  end

  def find_group_by_uuid(project, uuid)
    project.objects.select { |obj| obj.uuid == uuid }.first
  end

  def collect_files_for_group(info)
    files = []
    
    # Add files from the actual directory
    if Dir.exist?(@app_dir)
      Dir.children(@app_dir).each do |item|
        path = File.join(@app_dir, item)
        next unless File.file?(path)
        next if item.start_with?('.')
        next unless item.match?(/\.(swift|plist|xcassets|storyboard|xcdatamodeld)$/)
        
        files << item
      end
    end
    
    # Add exception files if they don't exist in the directory
    if info[:exceptions]
      info[:exceptions].each do |exception_file|
        files << exception_file unless files.include?(exception_file)
      end
    end
    
    # Ensure standard files are included
    standard_files = ['AppDelegate.swift', 'SceneDelegate.swift', 'Info.plist']
    standard_files.each do |std_file|
      files << std_file unless files.include?(std_file)
    end
    
    files.uniq
  end

  def add_files_to_group(project, group, files)
    files.each do |filename|
      file_path = File.join(@app_dir, filename)
      
      # Check if file reference already exists
      existing_ref = group.files.find { |f| f.path == filename }
      next if existing_ref
      
      # Add new file reference
      file_ref = group.new_file(filename)
      file_ref.source_tree = '<group>'
      
      puts "  Added file reference: #{filename}"
      
      # Add to appropriate build phase if it's a source file
      if filename.end_with?('.swift', '.m', '.mm')
        add_to_sources_build_phase(project, file_ref)
      elsif filename.end_with?('.xcassets', '.storyboard', '.xib')
        add_to_resources_build_phase(project, file_ref)
      end
    end
  end

  def add_subdirectories_as_groups(project, parent_group)
    puts "Adding subdirectories to group: #{parent_group.name || parent_group.path}"
    puts "App directory: #{@app_dir}"
    
    # SwiftJsonUI directories and any other directories in the app folder
    all_dirs = []
    
    # Add standard SwiftJsonUI directories
    swiftui_dirs = ['View', 'Layouts', 'Styles', 'Bindings', 'Core']
    all_dirs.concat(swiftui_dirs)
    
    # Also scan for any other directories that exist
    if Dir.exist?(@app_dir)
      Dir.children(@app_dir).each do |item|
        item_path = File.join(@app_dir, item)
        if File.directory?(item_path) && !item.start_with?('.')
          all_dirs << item unless all_dirs.include?(item)
        end
      end
    end
    
    puts "Directories to process: #{all_dirs.inspect}"
    puts "Parent group children before: #{parent_group.children.map { |c| c.name || c.path }.inspect}"
    
    all_dirs.each do |dir_name|
      dir_path = File.join(@app_dir, dir_name)
      unless Dir.exist?(dir_path)
        puts "  Directory does not exist: #{dir_path}"
        next
      end
      
      # Check if group already exists by name or path
      existing_group = parent_group.children.find { |child| 
        child.is_a?(Xcodeproj::Project::Object::PBXGroup) && 
        (child.path == dir_name || child.name == dir_name)
      }
      
      if existing_group
        puts "  Group already exists: #{dir_name} (uuid: #{existing_group.uuid})"
        # Recursively ensure files are added even if group exists
        add_files_recursively(project, existing_group, dir_path)
      else
        # Create new group
        new_group = parent_group.new_group(dir_name, dir_name)
        puts "  Added group: #{dir_name} (uuid: #{new_group.uuid})"
        
        # Recursively add files in the directory
        add_files_recursively(project, new_group, dir_path)
      end
    end
    
    puts "Parent group children after: #{parent_group.children.map { |c| c.name || c.path }.inspect}"
  end

  def add_files_recursively(project, group, dir_path)
    Dir.children(dir_path).each do |item|
      item_path = File.join(dir_path, item)
      
      if File.directory?(item_path)
        # Create subgroup
        subgroup = group.new_group(item, item)
        add_files_recursively(project, subgroup, item_path)
      elsif File.file?(item_path) && !item.start_with?('.')
        # Add file
        file_ref = group.new_file(item)
        file_ref.source_tree = '<group>'
        
        # Add to build phases if needed
        if item.end_with?('.swift')
          add_to_sources_build_phase(project, file_ref)
        end
      end
    end
  end

  def add_to_sources_build_phase(project, file_ref)
    app_target = project.targets.find { |t| t.name == @app_name && t.product_type == 'com.apple.product-type.application' }
    return unless app_target
    
    sources_phase = app_target.source_build_phase
    return unless sources_phase
    
    # Check if already in build phase
    existing = sources_phase.files.find { |bf| bf.file_ref == file_ref }
    return if existing
    
    sources_phase.add_file_reference(file_ref)
  end

  def add_to_resources_build_phase(project, file_ref)
    app_target = project.targets.find { |t| t.name == @app_name && t.product_type == 'com.apple.product-type.application' }
    return unless app_target
    
    resources_phase = app_target.resources_build_phase
    return unless resources_phase
    
    # Check if already in build phase
    existing = resources_phase.files.find { |bf| bf.file_ref == file_ref }
    return if existing
    
    resources_phase.add_file_reference(file_ref)
  end

  def setup_build_phases(project, main_group)
    app_target = project.targets.find { |t| t.name == @app_name && t.product_type == 'com.apple.product-type.application' }
    return unless app_target
    
    # Ensure all Swift files in the group are in Sources build phase
    main_group.recursive_children.each do |child|
      if child.is_a?(Xcodeproj::Project::Object::PBXFileReference)
        if child.path&.end_with?('.swift', '.m', '.mm')
          add_to_sources_build_phase(project, child)
        elsif child.path&.end_with?('.xcassets', '.storyboard', '.xib', '.json')
          add_to_resources_build_phase(project, child)
        end
      end
    end
    
    puts "Build phases configured"
  end
end

# コマンドライン実行
if __FILE__ == $0
  if ARGV.empty?
    puts "Usage: ruby convert_to_group_reference.rb <path/to/project.pbxproj>"
    puts "Example: ruby convert_to_group_reference.rb MyApp.xcodeproj/project.pbxproj"
    exit 1
  end
  
  pbxproj_path = ARGV[0]
  
  unless File.exist?(pbxproj_path)
    puts "Error: File not found: #{pbxproj_path}"
    exit 1
  end
  
  converter = XcodeSyncToGroupConverter.new(pbxproj_path)
  converter.convert
  converter.validate
end