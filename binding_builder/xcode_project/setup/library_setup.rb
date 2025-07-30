#!/usr/bin/env ruby

require "fileutils"
require "pathname"
require_relative "../pbxproj_manager"
require_relative "../../project_finder"
require_relative "../../config_manager"

class LibrarySetup < PbxprojManager
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

  def add_all_packages
    puts "Checking required packages..."
    
    # pbxprojファイルの内容を読み取り
    content = File.read(@project_file_path)
    
    # 必要なパッケージを決定
    packages_to_add = []
    
    # SwiftJsonUIは常に追加
    unless content.include?("SwiftJsonUI") && content.include?("Tai-Kimura/SwiftJsonUI")
      packages_to_add << {
        name: "SwiftJsonUI",
        repo_url: "https://github.com/Tai-Kimura/SwiftJsonUI",
        version: "6.0.0"
      }
    end
    
    # SimpleApiNetworkはuse_networkがtrueの場合のみ追加
    base_dir = File.expand_path('../..', File.dirname(__FILE__))
    use_network = ConfigManager.get_use_network(base_dir)
    
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
          "\t\t#{data[:package_ref_uuid]} /* XCRemoteSwiftPackageReference \"#{pkg[:name]}\" */ = {\n\t\t\tisa = XCRemoteSwiftPackageReference;\n\t\t\trepositoryURL = \"#{pkg[:repo_url]}\";\n\t\t\trequirement = {\n\t\t\t\tkind = upToNextMajorVersion;\n\t\t\t\tminimumVersion = #{pkg[:version]};\n\t\t\t};\n\t\t};"
        end.join("\n")
        
        content = content.gsub(
          /(\/* Begin XCRemoteSwiftPackageReference section \*\/.*?)([\s\S]*?)(\n\/* End XCRemoteSwiftPackageReference section \*\/)/m,
          "\\1\\2\n#{package_refs}\\3"
        )
      else
        # 新しいセクションを作成
        package_refs = package_data.map do |data|
          pkg = data[:package]
          "\t\t#{data[:package_ref_uuid]} /* XCRemoteSwiftPackageReference \"#{pkg[:name]}\" */ = {\n\t\t\tisa = XCRemoteSwiftPackageReference;\n\t\t\trepositoryURL = \"#{pkg[:repo_url]}\";\n\t\t\trequirement = {\n\t\t\t\tkind = upToNextMajorVersion;\n\t\t\t\tminimumVersion = #{pkg[:version]};\n\t\t\t};\n\t\t};"
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
        
        content = content.gsub(
          /(\s+)(minimizedProjectReferenceProxies = \d+;)/,
          "\\1\\2\n\\1packageReferences = (\n#{package_refs_list}\n\\1);"
        )
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
      project_name = ProjectFinder.detect_project_name(@project_file_path)
      package_deps_list = package_data.map do |data|
        "\t\t\t\t#{data[:package_dependency_uuid]} /* #{data[:package][:name]} */,"
      end.join("\n")
      
      content = content.gsub(
        /(name = #{project_name};[\s\S]*?packageProductDependencies = \(\s*)(.*?)(\s*\);)/m,
        "\\1\\2\n#{package_deps_list}\\3"
      )
      
      # Step 6: Frameworksセクションに追加
      puts "DEBUG: Step 6 - Adding to Frameworks section"
      frameworks_pattern = /([A-F0-9]{24} \/\* Frameworks \*\/ = \{\s+isa = PBXFrameworksBuildPhase;\s+buildActionMask = \d+;\s+files = \(\s*)(.*?)(\s*\);)/m
      if content.match(frameworks_pattern)
        build_files_list = package_data.map do |data|
          "\t\t\t\t#{data[:build_file_uuid]} /* #{data[:package][:name]} in Frameworks */,"
        end.join("\n")
        
        content = content.gsub(
          frameworks_pattern,
          "\\1\\2\n#{build_files_list}\\3"
        )
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


  def generate_uuid
    # Xcodeプロジェクトで使用される24桁の16進数UUIDを生成
    (0...24).map { "0123456789ABCDEF"[rand(16)] }.join
  end
end