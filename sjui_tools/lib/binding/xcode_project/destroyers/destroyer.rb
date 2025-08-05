#!/usr/bin/env ruby

require "fileutils"
require 'xcodeproj'
require_relative '../../../core/project_finder'
require_relative '../pbxproj_manager'
require_relative '../../../core/xcode_target_helper'

module SjuiTools
  module Binding
    module XcodeProject
      class Destroyer < PbxprojManager
        def initialize(project_file_path = nil)
          super(project_file_path)
        end

        protected

        def remove_from_xcode_project(file_names, created_files = [])
          return unless File.exist?(@project_file_path)
          
          puts "Removing from Xcode project..."
          
          begin
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
            
            # 各ファイルを削除
            file_names.each do |file_name|
              remove_file_from_project(project, file_name, app_targets)
            end
            
            # プロジェクトを保存
            project.save
            puts "Successfully removed from Xcode project"
            
          rescue => e
            puts "Error removing from Xcode project: #{e.message}"
            raise e
          end
        end

        def remove_file_from_project(project, file_name, targets)
          # プロジェクト内の全てのファイル参照を検索
          file_refs = []
          
          project.main_group.recursive_children.each do |child|
            if child.is_a?(Xcodeproj::Project::Object::PBXFileReference) && 
               (child.path == file_name || child.name == file_name)
              file_refs << child
            end
          end
          
          if file_refs.empty?
            puts "File not found in project: #{file_name}"
            return
          end
          
          # 各ターゲットから削除
          targets.each do |target|
            # ソースビルドフェーズから削除
            if target.source_build_phase
              target.source_build_phase.files.each do |build_file|
                if file_refs.include?(build_file.file_ref)
                  build_file.remove_from_project
                  puts "Removed #{file_name} from #{target.name} sources"
                end
              end
            end
            
            # リソースビルドフェーズから削除
            if target.resources_build_phase
              target.resources_build_phase.files.each do |build_file|
                if file_refs.include?(build_file.file_ref)
                  build_file.remove_from_project
                  puts "Removed #{file_name} from #{target.name} resources"
                end
              end
            end
          end
          
          # ファイル参照自体を削除
          file_refs.each do |file_ref|
            file_ref.remove_from_project
            puts "Removed file reference: #{file_name}"
          end
        end

        def delete_files(file_paths)
          deleted_files = []
          
          file_paths.each do |file_path|
            if File.exist?(file_path)
              File.delete(file_path)
              puts "Deleted: #{file_path}"
              deleted_files << file_path
            else
              puts "Warning: File not found: #{file_path}"
            end
          end
          
          deleted_files
        end

        def snake_name_from_camel(camel_name)
          camel_name.gsub(/([A-Z])/, '_\1').downcase.sub(/^_/, '')
        end
      end
    end
  end
end