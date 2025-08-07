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
    
    # Find main app synchronized group
    content.scan(/([A-F0-9]{24}) \/\* #{Regexp.escape(@app_name)} \*\/ = \{[^}]*?isa = PBXFileSystemSynchronized(?:Root)?Group;[^}]*?\}/m) do |match|
      uuid = match[0]
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
    end
    
    sync_groups
  end

  def convert_synchronized_to_regular_groups(sync_info)
    content = File.read(@pbxproj_path)
    
    sync_info.each do |info|
      next unless info[:type] == 'main_app'
      
      # Remove PBXFileSystemSynchronizedBuildFileExceptionSet section
      if content.include?("/* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section */")
        content.gsub!(
          /\/\* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section \*\/.*?\/\* End PBXFileSystemSynchronizedBuildFileExceptionSet section \*\//m,
          ''
        )
        puts "Removed PBXFileSystemSynchronizedBuildFileExceptionSet section"
      end
      
      # Convert the synchronized group to regular group
      content.gsub!(/(#{info[:uuid]} \/\* #{Regexp.escape(info[:name])} \*\/ = \{[^}]*?)isa = PBXFileSystemSynchronized(?:Root)?Group;([^}]*?)\}/m) do
        prefix = $1
        suffix = $2
        
        # Remove synchronized-specific properties
        suffix = suffix.gsub(/\s*exceptions = [^;]+;\s*/m, '')
        suffix = suffix.gsub(/\s*explicitFileTypes = \{[^}]*\};\s*/m, '')
        suffix = suffix.gsub(/\s*explicitFolders = \([^)]*\);\s*/m, '')
        
        # Change to PBXGroup
        "#{prefix}isa = PBXGroup;#{suffix}}"
      end
      
      # Remove fileSystemSynchronizedGroups references
      content.gsub!(/fileSystemSynchronizedGroups = \([^)]*#{info[:uuid]}[^)]*\);/m) do |match|
        # Check if there are other groups in the list
        other_groups = match.gsub(/#{info[:uuid]} \/\* #{Regexp.escape(info[:name])} \*\/,?/, '').strip
        if other_groups.match(/\((\s*)\)/)
          # Empty list, remove the entire property
          ''
        else
          # Keep other groups
          other_groups
        end
      end
      
      puts "Converted #{info[:name]} from synchronized to regular group"
    end
    
    # Save the converted file
    File.write(@pbxproj_path, content)
    puts "Saved initial conversion"
  end

  def manage_with_xcodeproj(sync_info)
    # Now use xcodeproj gem to properly manage the project
    project = Xcodeproj::Project.open(@xcodeproj_path)
    
    sync_info.each do |info|
      next unless info[:type] == 'main_app'
      
      # Find the converted group
      main_group = find_group_by_uuid(project, info[:uuid])
      next unless main_group
      
      puts "Managing files for group: #{info[:name]}"
      
      # Don't clear existing children - just add missing files and directories
      # main_group.clear  # REMOVED: This was deleting existing directory references
      
      # Get list of files to add
      files_to_add = collect_files_for_group(info)
      
      # Add files to the group
      add_files_to_group(project, main_group, files_to_add)
      
      # Add existing subdirectories as groups
      add_subdirectories_as_groups(project, main_group)
      
      # Handle build phases
      setup_build_phases(project, main_group)
    end
    
    # Save the project
    project.save
    puts "Project saved with xcodeproj gem"
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
    
    all_dirs.each do |dir_name|
      dir_path = File.join(@app_dir, dir_name)
      next unless Dir.exist?(dir_path)
      
      # Check if group already exists by name or path
      existing_group = parent_group.children.find { |child| 
        child.is_a?(Xcodeproj::Project::Object::PBXGroup) && 
        (child.path == dir_name || child.name == dir_name)
      }
      
      if existing_group
        puts "  Group already exists: #{dir_name}"
        # Recursively ensure files are added even if group exists
        add_files_recursively(project, existing_group, dir_path)
      else
        # Create new group
        new_group = parent_group.new_group(dir_name, dir_name)
        puts "  Added group: #{dir_name}"
        
        # Recursively add files in the directory
        add_files_recursively(project, new_group, dir_path)
      end
    end
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