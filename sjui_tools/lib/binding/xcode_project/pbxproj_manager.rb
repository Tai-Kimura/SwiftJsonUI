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
            raise ArgumentError, "project_file_path is required"
          end
          
          # ConfigManagerを使用してsource_directoryを設定
          config = Core::ConfigManager.load_config
          @source_directory = config['source_directory'] || ''
          @hot_loader_directory = config['hot_loader_directory'] || ''
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
            
            # 除外すべきディレクトリとファイル
            directories_to_exclude = [
              'sjui_tools',
              'binding_builder',
              '.git',
              '.github',
              '.build',
              '.swiftpm',
              'Tests',
              'UITests',
              'Docs',
              'docs',
              'config',
              'installer'
            ]
            
            # 除外すべきファイル（ルートレベル）
            files_to_exclude = [
              'README.md',
              'LICENSE',
              'CHANGELOG.md',
              '.DS_Store',
              '.gitignore',
              'Podfile',
              'Podfile.lock',
              'Package.swift',
              'Package.resolved',
              'VERSION'
            ]
            
            # プロジェクトのメインルートグループを取得
            main_group = project.main_group
            
            # 各ターゲットから除外
            app_targets.each do |target|
              # ディレクトリの除外
              directories_to_exclude.each do |dir_name|
                if group = main_group.find_subpath(dir_name, true)
                  exclude_group_from_target(group, target)
                end
              end
              
              # ファイルの除外
              files_to_exclude.each do |file_name|
                # ルートグループ直下のファイルを探す
                file_ref = main_group.files.find { |f| f.name == file_name || f.path == file_name }
                if file_ref
                  # ビルドフェーズから除外
                  target.build_phases.each do |phase|
                    if phase.respond_to?(:files)
                      phase.files.each do |build_file|
                        if build_file.file_ref == file_ref
                          puts "Excluding file from target: #{file_name}"
                          phase.remove_build_file(build_file)
                        end
                      end
                    end
                  end
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

      end
    end
  end
end