#!/usr/bin/env ruby

require "fileutils"
require_relative "../../project_finder"
require_relative "../pbxproj_manager"

class Destroyer < PbxprojManager
  def initialize(project_file_path = nil)
    super(project_file_path)
  end

  protected

  def remove_from_xcode_project(file_names, created_files = [], &block)
    return unless File.exist?(@project_file_path)
    
    puts "Removing from Xcode project..."
    
    safe_pbxproj_operation(file_names, created_files) do
      # プロジェクトファイルを読み取り
      project_content = File.read(@project_file_path)
      
      # ファイルがプロジェクトに含まれているかチェック
      if file_names.none? { |file_name| project_content.include?(file_name) }
        puts "Files are not in the project, skipping Xcode project removal"
        return
      end
      
      # ファイルに関連するエントリを削除
      if block_given?
        remove_entries_from_project_with_block(project_content, &block)
      else
        remove_entries_from_project(project_content, file_names)
      end
      
      # プロジェクトファイルを書き戻し
      File.write(@project_file_path, project_content)
      puts "Successfully removed from Xcode project"
    end
  end

  def remove_entries_from_project(project_content, file_names)
    lines = project_content.lines
    
    # UUIDを収集してから削除を行う
    uuids_to_remove = collect_uuids_for_files(lines, file_names)
    
    remove_entries_by_uuids(project_content, lines, uuids_to_remove)
  end

  def remove_entries_from_project_with_block(project_content, &block)
    lines = project_content.lines
    
    # ブロックを使用してUUIDを収集
    uuids_to_remove = block.call(lines)
    
    remove_entries_by_uuids(project_content, lines, uuids_to_remove)
  end

  def remove_entries_by_uuids(project_content, lines, uuids_to_remove)
    if uuids_to_remove.empty?
      puts "No UUIDs found for the files to remove"
      return
    end
    
    puts "Found UUIDs to remove: #{uuids_to_remove}"
    
    # 削除すべき行範囲を特定（マルチライン構造に対応）
    ranges_to_remove = []
    
    lines.each_with_index do |line, index|
      uuids_to_remove.each do |uuid|
        if line.include?(uuid)
          # PBXGroupの場合は複数行削除が必要
          if line.include?("= {isa = PBXGroup")
            end_line = find_closing_brace(lines, index)
            ranges_to_remove << (index..end_line)
            puts "Found multi-line PBXGroup entry: lines #{index + 1}-#{end_line + 1}"
          else
            ranges_to_remove << (index..index)
          end
          break
        end
      end
    end
    
    # 範囲を統合して重複を除去
    ranges_to_remove = merge_ranges(ranges_to_remove)
    
    # 逆順で削除（行番号がずれないように）
    ranges_to_remove.reverse.each do |range|
      if range.first == range.last
        puts "Removing line #{range.first + 1}: #{lines[range.first].strip}"
        lines.delete_at(range.first)
      else
        puts "Removing lines #{range.first + 1}-#{range.last + 1}"
        (range.last - range.first + 1).times { lines.delete_at(range.first) }
      end
    end
    
    project_content.replace(lines.join)
    puts "Removed entries from project file"
  end

  def find_closing_brace(lines, start_index)
    brace_count = 0
    (start_index...lines.length).each do |i|
      line = lines[i]
      brace_count += line.count('{')
      brace_count -= line.count('}')
      if brace_count == 0 && line.include?('}')
        return i
      end
    end
    start_index # fallback
  end

  def merge_ranges(ranges)
    return ranges if ranges.empty?
    
    sorted_ranges = ranges.sort_by(&:first)
    merged = [sorted_ranges.first]
    
    sorted_ranges[1..-1].each do |range|
      last_merged = merged.last
      if range.first <= last_merged.last + 1
        merged[-1] = (last_merged.first..[last_merged.last, range.last].max)
      else
        merged << range
      end
    end
    
    merged
  end

  def collect_uuids_for_files(lines, file_names)
    uuids = []
    
    lines.each do |line|
      file_names.each do |file_name|
        # PBXFileReference entries - より厳密なマッチング
        if line.match(/([A-F0-9]{24}) \/\* #{Regexp.escape(file_name)} \*\/ = \{isa = PBXFileReference/)
          uuids << $1
          puts "Found FileReference UUID for #{file_name}: #{$1}"
        # PBXBuildFile entries (Sources)
        elsif line.match(/([A-F0-9]{24}) \/\* #{Regexp.escape(file_name)} in Sources \*\/ = \{isa = PBXBuildFile/)
          uuids << $1
          puts "Found BuildFile UUID for #{file_name}: #{$1}"
        # PBXBuildFile entries (Resources)
        elsif line.match(/([A-F0-9]{24}) \/\* #{Regexp.escape(file_name)} in Resources \*\/ = \{isa = PBXBuildFile/)  
          uuids << $1
          puts "Found BuildFile UUID for #{file_name}: #{$1}"
        end
      end
    end
    
    uuids.uniq
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

  def remove_entries_from_project_content(file_names)
    return unless File.exist?(@project_file_path)
    puts "Removing entries from project content..."
    
    # バックアップ作成
    backup_path = create_backup(@project_file_path)
    
    begin
      # プロジェクトファイルを読み取り
      project_content = File.read(@project_file_path)
      
      # ファイルに関連するエントリを削除
      remove_entries_from_project(project_content, file_names)
      
      # プロジェクトファイルを書き戻し
      File.write(@project_file_path, project_content)
      
      # 整合性をチェック
      if validate_pbxproj(@project_file_path)
        puts "✅ Entries removed from project content successfully"
        cleanup_backup(backup_path)
      else
        puts "❌ pbxproj file validation failed, rolling back..."
        FileUtils.copy(backup_path, @project_file_path)
        cleanup_backup(backup_path)
        raise "pbxproj file corruption detected after removing entries"
      end
      
    rescue => e
      puts "Error during entry removal: #{e.message}"
      if File.exist?(backup_path)
        FileUtils.copy(backup_path, @project_file_path)
        cleanup_backup(backup_path)
        puts "Restored pbxproj file from backup"
      end
      raise e
    end
  end
end