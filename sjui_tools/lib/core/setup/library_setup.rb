#!/usr/bin/env ruby

require "fileutils"
require "pathname"
require "json"
require_relative '../../binding/xcode_project/pbxproj_manager'
require_relative '../../binding/project_finder'
require_relative '../config_manager'
require_relative "library_setup_helper"

module SjuiTools
  module Core
    module Setup
      class LibrarySetup < ::PbxprojManager
  def initialize(project_file_path = nil)
    super(project_file_path)
  end

  def setup_libraries
    puts "Setting up required libraries..."
    
    # 必要なパッケージを一括で追加
    add_all_packages
    
    puts "Library setup completed successfully!"
  end

  private
  
  def get_current_version
    base_dir = File.expand_path('../..', File.dirname(__FILE__))
    version_file = File.join(base_dir, 'VERSION')
    
    if File.exist?(version_file)
      File.read(version_file).strip
    else
      "default"
    end
  end
  
  def load_library_versions
    base_dir = File.expand_path('../..', File.dirname(__FILE__))
    versions_file = File.join(base_dir, 'config', 'library_versions.json')
    
    if File.exist?(versions_file)
      begin
        JSON.parse(File.read(versions_file))
      rescue JSON::ParserError => e
        puts "Warning: Failed to parse library_versions.json: #{e.message}"
        nil
      end
    else
      nil
    end
  end
  
  def get_library_config(library_name, current_version)
    versions_config = load_library_versions
    return nil unless versions_config
    
    version_mappings = versions_config['version_mappings'] || {}
    
    # Try exact version match first
    if version_mappings[current_version] && version_mappings[current_version][library_name]
      return version_mappings[current_version][library_name]
    end
    
    # Fallback to default
    if version_mappings['default'] && version_mappings['default'][library_name]
      return version_mappings['default'][library_name]
    end
    
    nil
  end

  def add_all_packages
    puts "Checking required packages..."
    
    # Get current version
    current_version = get_current_version
    puts "Using binding_builder version: #{current_version}"
    
    # pbxprojファイルの内容を読み取り
    content = File.read(@project_file_path)
    
    # 必要なパッケージを決定
    packages_to_add = []
    
    # SwiftJsonUIは常に追加
    unless content.include?("SwiftJsonUI") && content.include?("Tai-Kimura/SwiftJsonUI")
      swiftjsonui_config = get_library_config("SwiftJsonUI", current_version)
      
      if swiftjsonui_config
        package_info = {
          name: "SwiftJsonUI",
          repo_url: swiftjsonui_config['git'] || "https://github.com/Tai-Kimura/SwiftJsonUI"
        }
        
        # Version requirement based on configuration
        if swiftjsonui_config['branch']
          package_info[:branch] = swiftjsonui_config['branch']
        elsif swiftjsonui_config['from']
          package_info[:version] = swiftjsonui_config['from']
        elsif swiftjsonui_config['exact']
          package_info[:exact_version] = swiftjsonui_config['exact']
        else
          package_info[:version] = "6.0.0" # default
        end
        
        packages_to_add << package_info
      else
        # Fallback if no config found
        packages_to_add << {
          name: "SwiftJsonUI",
          repo_url: "https://github.com/Tai-Kimura/SwiftJsonUI",
          version: "6.0.0"
        }
      end
    end
    
    # SimpleApiNetworkはuse_networkがtrueの場合のみ追加
    use_network = ::SjuiTools::Core::ConfigManager.get_use_network
    
    if use_network && !(content.include?("SimpleApiNetwork") && content.include?("Tai-Kimura/SimpleApiNetwork"))
      packages_to_add << {
        name: "SimpleApiNetwork", 
        repo_url: "https://github.com/Tai-Kimura/SimpleApiNetwork",
        version: "2.1.8"
      }
    end
    
    if packages_to_add.empty?
      puts "All required packages already exist in the project"
      return
    end
    
    puts "Adding packages: #{packages_to_add.map { |p| p[:name] }.join(', ')}"
    
    safe_pbxproj_operation([], []) do
      add_packages_to_pbxproj(packages_to_add)
      puts "Successfully added packages to Xcode project"
    end
  end

  def add_packages_to_pbxproj(packages)
    puts "DEBUG: Starting add_packages_to_pbxproj with #{packages.size} packages"
    
    # バックアップ作成
    backup_path = create_backup(@project_file_path)
    
    begin
      content = File.read(@project_file_path)
      puts "DEBUG: Original file size: #{content.length}"
      
      # 各パッケージのUUIDを生成
      package_data = packages.map do |pkg|
        {
          package: pkg,
          package_ref_uuid: generate_uuid,
          package_dependency_uuid: generate_uuid,
          build_file_uuid: generate_uuid
        }
      end
      
      puts "DEBUG: Generated UUIDs for #{package_data.size} packages"
      package_data.each do |data|
        puts "  #{data[:package][:name]}: ref=#{data[:package_ref_uuid]}, dep=#{data[:package_dependency_uuid]}, build=#{data[:build_file_uuid]}"
      end
      
      # Step 1: XCRemoteSwiftPackageReferenceセクションを追加
      puts "DEBUG: Step 1 - Adding XCRemoteSwiftPackageReference section"
      if content.include?("/* Begin XCRemoteSwiftPackageReference section */")
        # 既存のセクションに追加
        package_refs = package_data.map do |data|
          pkg = data[:package]
          requirement_str = build_requirement_string(pkg)
          "\t\t#{data[:package_ref_uuid]} /* XCRemoteSwiftPackageReference \"#{pkg[:name]}\" */ = {\n\t\t\tisa = XCRemoteSwiftPackageReference;\n\t\t\trepositoryURL = \"#{pkg[:repo_url]}\";\n\t\t\trequirement = {\n#{requirement_str}\n\t\t\t};\n\t\t};"
        end.join("\n")
        
        content = content.gsub(
          /(\/* Begin XCRemoteSwiftPackageReference section \*\/.*?)([\s\S]*?)(\n\/* End XCRemoteSwiftPackageReference section \*\/)/m,
          "\\1\\2\n#{package_refs}\\3"
        )
      else
        # 新しいセクションを作成
        package_refs = package_data.map do |data|
          pkg = data[:package]
          requirement_str = build_requirement_string(pkg)
          "\t\t#{data[:package_ref_uuid]} /* XCRemoteSwiftPackageReference \"#{pkg[:name]}\" */ = {\n\t\t\tisa = XCRemoteSwiftPackageReference;\n\t\t\trepositoryURL = \"#{pkg[:repo_url]}\";\n\t\t\trequirement = {\n#{requirement_str}\n\t\t\t};\n\t\t};"
        end.join("\n")
        
        content = content.gsub(
          /(\/* End XCConfigurationList section \*\/)/,
          "\\1\n\n/* Begin XCRemoteSwiftPackageReference section */\n#{package_refs}\n/* End XCRemoteSwiftPackageReference section */"
        )
      end
      
      # Step 2: XCSwiftPackageProductDependencyセクションを追加
      puts "DEBUG: Step 2 - Adding XCSwiftPackageProductDependency section"
      if content.include?("/* Begin XCSwiftPackageProductDependency section */")
        # 既存のセクションに追加
        package_deps = package_data.map do |data|
          pkg = data[:package]
          "\t\t#{data[:package_dependency_uuid]} /* #{pkg[:name]} */ = {\n\t\t\tisa = XCSwiftPackageProductDependency;\n\t\t\tpackage = #{data[:package_ref_uuid]} /* XCRemoteSwiftPackageReference \"#{pkg[:name]}\" */;\n\t\t\tproductName = #{pkg[:name]};\n\t\t};"
        end.join("\n")
        
        content = content.gsub(
          /(\/* Begin XCSwiftPackageProductDependency section \*\/.*?)([\s\S]*?)(\n\/* End XCSwiftPackageProductDependency section \*\/)/m,
          "\\1\\2\n#{package_deps}\\3"
        )
      else
        # 新しいセクションを作成
        package_deps = package_data.map do |data|
          pkg = data[:package]
          "\t\t#{data[:package_dependency_uuid]} /* #{pkg[:name]} */ = {\n\t\t\tisa = XCSwiftPackageProductDependency;\n\t\t\tpackage = #{data[:package_ref_uuid]} /* XCRemoteSwiftPackageReference \"#{pkg[:name]}\" */;\n\t\t\tproductName = #{pkg[:name]};\n\t\t};"
        end.join("\n")
        
        content = content.gsub(
          /(\/* End XCRemoteSwiftPackageReference section \*\/)/,
          "\\1\n\n/* Begin XCSwiftPackageProductDependency section */\n#{package_deps}\n/* End XCSwiftPackageProductDependency section */"
        )
      end
      
      # Step 3: PBXBuildFileセクションを追加
      puts "DEBUG: Step 3 - Adding PBXBuildFile section"
      if content.include?("/* Begin PBXBuildFile section */")
        # 既存のセクションに追加
        build_files = package_data.map do |data|
          "\t\t#{data[:build_file_uuid]} /* #{data[:package][:name]} in Frameworks */ = {isa = PBXBuildFile; productRef = #{data[:package_dependency_uuid]} /* #{data[:package][:name]} */; };"
        end.join("\n")
        
        content = content.gsub(
          /(\/* Begin PBXBuildFile section \*\/\n)/,
          "\\1#{build_files}\n"
        )
      else
        # 新しいセクションを作成
        build_files = package_data.map do |data|
          "\t\t#{data[:build_file_uuid]} /* #{data[:package][:name]} in Frameworks */ = {isa = PBXBuildFile; productRef = #{data[:package_dependency_uuid]} /* #{data[:package][:name]} */; };"
        end.join("\n")
        
        content = content.gsub(
          /(\/\* Begin PBXContainerItemProxy section \*\/)/,
          "/* Begin PBXBuildFile section */\n#{build_files}\n/* End PBXBuildFile section */\n\n\\1"
        )
      end
      
      # Step 4: packageReferencesを追加（PBXProjectセクション内）
      puts "DEBUG: Step 4 - Adding packageReferences"
      unless content.include?("packageReferences = (")
        package_refs_list = package_data.map do |data|
          "\t\t\t\t#{data[:package_ref_uuid]} /* XCRemoteSwiftPackageReference \"#{data[:package][:name]}\" */,"
        end.join("\n")
        
        # Use helper to insert packageReferences
        content = LibrarySetupHelper.insert_package_references_in_project(content, package_refs_list)
      else
        # 既存のpackageReferencesに追加
        package_refs_list = package_data.map do |data|
          "\t\t\t\t#{data[:package_ref_uuid]} /* XCRemoteSwiftPackageReference \"#{data[:package][:name]}\" */,"
        end.join("\n")
        
        content = content.gsub(
          /(packageReferences = \(\s*)(.*?)(\s*\);)/m,
          "\\1\\2\n#{package_refs_list}\\3"
        )
      end
      
      # Step 5: packageProductDependenciesをプロジェクトターゲットに追加
      puts "DEBUG: Step 5 - Adding packageProductDependencies"
      project_name = ::ProjectFinder.detect_project_name(@project_file_path)
      package_deps_list = package_data.map do |data|
        "\t\t\t\t#{data[:package_dependency_uuid]} /* #{data[:package][:name]} */,"
      end.join("\n")
      
      # Check if packageProductDependencies already exists in the target
      if content.match(/#{Regexp.escape(project_name)}.*?packageProductDependencies = \(/m)
        # Already exists, add to it
        content = content.gsub(
          /(#{Regexp.escape(project_name)}.*?packageProductDependencies = \(\s*)(.*?)(\s*\);)/m,
          "\\1\\2#{package_deps_list}\\3"
        )
      else
        # Doesn't exist, use helper to insert it
        content = LibrarySetupHelper.insert_package_product_dependencies_in_target(content, project_name, package_deps_list)
      end
      
      # Step 6: Frameworksセクションに追加（メインアプリターゲットのみ）
      puts "DEBUG: Step 6 - Adding to Frameworks section"
      
      # Find main app target's framework build phase
      project_name = ::ProjectFinder.detect_project_name(@project_file_path)
      
      # First, find the main app target UUID
      target_match = content.match(/([A-F0-9]{24}) \/\* #{Regexp.escape(project_name)} \*\/ = \{[^}]*?isa = PBXNativeTarget[^}]*?productType = "com\.apple\.product-type\.application"[^}]*?\}/m)
      
      if target_match
        target_uuid = target_match[1]
        
        # Find the build phases for this target
        if build_phases_match = content.match(/#{target_uuid} \/\* #{Regexp.escape(project_name)} \*\/ = \{[^}]*?buildPhases = \(\s*(.*?)\s*\);/m)
          build_phases = build_phases_match[1]
          
          # Find the frameworks build phase UUID
          if frameworks_uuid_match = build_phases.match(/([A-F0-9]{24}) \/\* Frameworks \*\//)
            frameworks_uuid = frameworks_uuid_match[1]
            
            # Now add to this specific frameworks build phase
            frameworks_pattern = /(#{frameworks_uuid} \/\* Frameworks \*\/ = \{\s+isa = PBXFrameworksBuildPhase;\s+buildActionMask = \d+;\s+files = \(\s*)(.*?)(\s*\);)/m
            
            if content.match(frameworks_pattern)
              build_files_list = package_data.map do |data|
                "\t\t\t\t#{data[:build_file_uuid]} /* #{data[:package][:name]} in Frameworks */,"
              end.join("\n")
              
              content = content.gsub(
                frameworks_pattern,
                "\\1\\2\n#{build_files_list}\\3"
              )
            end
          end
        end
      end
      
      # ファイルに書き込み
      File.write(@project_file_path, content)
      puts "DEBUG: All steps complete, file size: #{content.length}"
      
      # 整合性検証
      if validate_pbxproj(@project_file_path)
        puts "✅ All packages added successfully"
        cleanup_backup(backup_path)
      else
        puts "❌ pbxproj validation failed, rolling back..."
        FileUtils.copy(backup_path, @project_file_path)
        cleanup_backup(backup_path)
        raise "pbxproj file corruption detected after package addition"
      end
      
    rescue => e
      puts "Error during package addition: #{e.message}"
      if File.exist?(backup_path)
        FileUtils.copy(backup_path, @project_file_path)
        cleanup_backup(backup_path)
        puts "Restored pbxproj file from backup"
      end
      raise e
    end
  end


  def build_requirement_string(package)
    if package[:branch]
      # Xcode 16形式: branchの値を引用符で囲む
      "\t\t\t\tbranch = \"#{package[:branch]}\";\n\t\t\t\tkind = branch;"
    elsif package[:exact_version]
      "\t\t\t\tkind = exactVersion;\n\t\t\t\tversion = \"#{package[:exact_version]}\";"
    elsif package[:version]
      "\t\t\t\tkind = upToNextMajorVersion;\n\t\t\t\tminimumVersion = \"#{package[:version]}\";"
    else
      # Default to version 1.0.0 if nothing specified
      "\t\t\t\tkind = upToNextMajorVersion;\n\t\t\t\tminimumVersion = \"1.0.0\";"
    end
  end

  def generate_uuid
    # Xcodeプロジェクトで使用される24桁の16進数UUIDを生成
    (0...24).map { "0123456789ABCDEF"[rand(16)] }.join
  end
      end
    end
  end
end