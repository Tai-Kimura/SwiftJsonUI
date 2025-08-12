# frozen_string_literal: true

require "json"
require "time"

module SjuiTools
  module UIKit
    class BuildCacheManager
      def initialize(base_path = nil)
        @base_path = base_path || Core::BasePath.root
        @cache_dir = File.join(@base_path, '.sjui_cache')
        FileUtils.mkdir_p(@cache_dir) unless Dir.exist?(@cache_dir)
        @last_updated_file = File.join(@cache_dir, "last_updated.txt")
        @including_file = File.join(@cache_dir, "including.json")
      end

      # 最後の更新時刻を取得
      def load_last_updated
        return nil unless File.exist?(@last_updated_file)
        
        File.open(@last_updated_file, "r") do |file|
          begin
            Time.parse(file.read)
          rescue => ex
            puts ex.message
            nil
          end
        end
      end

      # 前回のincludingファイル情報を取得
      def load_last_including_files
        return {} unless File.exist?(@including_file)
        
        File.open(@including_file, "r") do |file|
          JSON.load(file)
        end
      rescue => ex
        puts "Error loading including files: #{ex.message}"
        {}
      end

      # ファイルが更新が必要かチェック
      def needs_update?(file_path, last_updated, layout_path, last_including_files)
        return true if last_updated.nil?
        
        file_name = File.basename(file_path, ".*")
        stat = File::Stat.new(file_path)
        
        puts "file updated: #{stat.mtime}"
        
        # ファイル自体の更新時刻をチェック
        return true if stat.mtime > last_updated
        
        # includingファイルの更新時刻をチェック
        including_files = last_including_files[file_name]
        return true if including_files.nil?
        
        including_files.each do |f|
          # サブディレクトリを含むパスをサポート
          if f.include?('/')
            # サブディレクトリがある場合
            dir_parts = f.split('/')
            file_base = dir_parts.pop
            dir_path = dir_parts.join('/')
            
            # まずpartial用の_プレフィックス付きファイルを探す
            included_file_path = File.join(layout_path, dir_path, "_#{file_base}.json")
            if !File.exist?(included_file_path)
              # 次に通常のファイルを探す
              included_file_path = File.join(layout_path, "#{f}.json")
            end
          else
            # サブディレクトリがない場合
            # まずpartial用の_プレフィックス付きファイルを探す
            included_file_path = File.join(layout_path, "_#{f}.json")
            if !File.exist?(included_file_path)
              # 次に通常のファイルを探す
              included_file_path = File.join(layout_path, "#{f}.json")
            end
          end
          
          next unless File.exist?(included_file_path)
          
          included_stat = File::Stat.new(included_file_path)
          return true if included_stat.mtime > last_updated
        end
        
        false
      end

      # キャッシュを保存
      def save_cache(including_files)
        # including.jsonを保存（整形付き）
        File.open(@including_file, "w") do |file|
          file.write(JSON.pretty_generate(including_files))
        end
        
        # last_updated.txtを保存
        File.open(@last_updated_file, "w") do |file|
          file.write(Time.now)
        end
      end
    end
  end
end