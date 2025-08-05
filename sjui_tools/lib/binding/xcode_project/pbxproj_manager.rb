#!/usr/bin/env ruby

require "fileutils"
require "pathname"
require_relative '../../core/project_finder'
require_relative '../../core/config_manager'
require_relative '../../core/xcode_target_helper'

module SjuiTools
  module Binding
    module XcodeProject
      class PbxprojManager
        def initialize(project_file_path = nil)
    if project_file_path
      @project_file_path = project_file_path
      @project_root = Core::ProjectFinder.get_project_root(@project_file_path)
    else
      # 後方互換性のため、引数なしの場合は従来通り検索
      @binding_builder_dir = File.expand_path("../../", __FILE__)
      @project_root = File.dirname(@binding_builder_dir)
      @project_file_path = find_project_file
    end
    
    # ConfigManagerを使用してsource_directoryを設定
    config = Core::ConfigManager.load_config
    @source_directory = config['source_directory'] || ''
    @hot_loader_directory = config['hot_loader_directory'] || ''
  end

  def safe_pbxproj_operation(modified_files = [], created_files = [])
    unless @project_file_path && File.exist?(@project_file_path)
      puts "Error: Could not find project.pbxproj file"
      raise "Project file not found: #{@project_file_path}"
    end
    
    # プロジェクトファイルのバックアップを作成
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    backup_path = "#{@project_file_path}.backup_#{timestamp}"
    
    begin
      FileUtils.copy(@project_file_path, backup_path)
      puts "Created backup: #{backup_path}"
      
      # 操作を実行
      yield
      
      # バックアップを削除
      File.delete(backup_path)
      puts "Operation completed successfully, removed backup"
      
    rescue => e
      puts "Error during pbxproj operation: #{e.message}"
      puts "Rolling back changes..."
      
      # プロジェクトファイルを復元
      FileUtils.copy(backup_path, @project_file_path)
      puts "Restored project file from backup"
      
      # 作成されたファイルを削除
      created_files.each do |file_path|
        if File.exist?(file_path)
          File.delete(file_path)
          puts "Deleted created file: #{file_path}"
        end
      end
      
      # 修正されたファイルの通知（手動で元に戻す必要がある）
      unless modified_files.empty?
        puts "The following files were modified and may need manual restoration:"
        modified_files.each { |f| puts "  - #{f}" }
      end
      
      # バックアップファイルを削除
      File.delete(backup_path)
      
      # エラーを再発生
      raise e
    end
  end

  def is_safe_file_path?(file_path)
    # Xcodeプロジェクトで問題を起こす可能性のある文字をチェック
    unsafe_chars = ['<', '>', ':', '"', '|', '?', '*', "\0"]
    unsafe_chars.none? { |char| file_path.include?(char) }
  end


  def setup_membership_exceptions
    return unless File.exist?(@project_file_path)
    
    puts "Setting up file exclusions for sjui_tools directory..."
    
    begin
      require 'xcodeproj'
      
      # .xcodeprojディレクトリを見つける
      if @project_file_path.end_with?('.pbxproj')
        xcodeproj_path = File.dirname(File.dirname(@project_file_path))
      else
        xcodeproj_path = @project_file_path
      end
      
      # プロジェクトを開く
      project = Xcodeproj::Project.open(xcodeproj_path)
      
      # アプリターゲットを取得
      app_targets = Core::XcodeTargetHelper.get_app_targets(project)
      return if app_targets.empty?
      
      # sjui_toolsディレクトリのファイルを除外
      directories_to_exclude = ['sjui_tools']
      
      # プロジェクトのメインルートグループを取得
      main_group = project.main_group
      
      # 各ターゲットから除外
      app_targets.each do |target|
        directories_to_exclude.each do |dir_name|
          if group = main_group.find_subpath(dir_name, true)
            exclude_group_from_target(group, target)
          end
        end
      end
      
      # プロジェクトを保存
      project.save
      puts "✅ Membership exceptions set successfully using xcodeproj gem"
      
    rescue LoadError
      puts "xcodeproj gem not found. Please install it with: gem install xcodeproj"
      raise LoadError, "xcodeproj gem is required for this operation"
    rescue => e
      puts "Error setting membership exceptions with xcodeproj: #{e.message}"
      raise e
    end
  end
  
  private
  
  def exclude_group_from_target(group, target)
    # グループ内のすべてのファイルを再帰的に除外
    group.recursive_children.each do |child|
      if child.is_a?(Xcodeproj::Project::Object::PBXFileReference)
        # ファイルがターゲットのビルドフェーズに含まれている場合は削除
        target.source_build_phase.files.each do |build_file|
          if build_file.file_ref == child
            build_file.remove_from_project
          end
        end
        
        target.resources_build_phase.files.each do |build_file|
          if build_file.file_ref == child
            build_file.remove_from_project
          end
        end
      end
    end
  end

  protected

  def find_project_file
    # ProjectFinderを使用してプロジェクトファイルを検索
    binding_builder_dir = File.expand_path("../../", __FILE__)
    Core::ProjectFinder.find_project_file(binding_builder_dir)
  end

  def create_backup(file_path)
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    backup_path = "#{file_path}.backup_#{timestamp}"
    FileUtils.copy(file_path, backup_path)
    puts "Created backup: #{backup_path}"
    backup_path
  end

  def cleanup_backup(backup_path)
    if File.exist?(backup_path)
      File.delete(backup_path)
      puts "Cleaned up backup: #{backup_path}"
    end
  end

  def validate_pbxproj(file_path)
    return false unless File.exist?(file_path)
    
    begin
      # plutilコマンドを使用してpbxprojファイルの構文をチェック
      result = `plutil -lint "#{file_path}" 2>&1`
      exit_status = $?.exitstatus
      
      if exit_status == 0
        puts "pbxproj validation passed (plutil syntax check successful)"
        return true
      else
        puts "pbxproj validation failed:"
        puts result
        return false
      end
      
    rescue => e
      puts "pbxproj validation error: #{e.message}"
      
      # plutilが利用できない場合はフォールバック検証
      puts "Falling back to basic validation..."
      return basic_pbxproj_validation(file_path)
    end
  end

  private

  def basic_pbxproj_validation(file_path)
    begin
      content = File.read(file_path)
      
      # 基本的な構造チェック
      return false unless content.include?("// !$*UTF8*$!")
      return false unless content.include?("archiveVersion = 1;")
      return false unless content.include?("objectVersion =")
      
      # 括弧のバランスチェック
      open_braces = content.count('{')
      close_braces = content.count('}')
      if open_braces != close_braces
        puts "Brace mismatch: #{open_braces} open braces, #{close_braces} close braces"
        return false
      end
      
      puts "pbxproj basic validation passed"
      true
      
    rescue => e
      puts "pbxproj basic validation error: #{e.message}"
      false
    end
  end

  def rollback_changes(backup_path, created_files = [])
    puts "Rolling back changes..."
    
    # 作成されたファイルを削除
    created_files.each do |file_path|
      if File.exist?(file_path)
        # フォルダとファイルを削除
        File.delete(file_path)
        puts "Deleted created file: #{file_path}"
        
        # 空のフォルダも削除
        folder_path = File.dirname(file_path)
        if Dir.exist?(folder_path) && Dir.empty?(folder_path)
          Dir.rmdir(folder_path)
          puts "Deleted empty folder: #{folder_path}"
        end
      end
    end
    
    # pbxprojファイルを復元
    if File.exist?(backup_path)
      FileUtils.copy(backup_path, @project_file_path)
      puts "Restored pbxproj file from backup"
    end
  end
      end
    end
  end
end