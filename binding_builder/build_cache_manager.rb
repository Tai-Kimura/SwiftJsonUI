require "json"
require "time"

class BuildCacheManager
  def initialize(base_path)
    @base_path = base_path
    @last_updated_file = File.expand_path(@base_path) + "/last_updated.txt"
    @including_file = File.expand_path(@base_path) + "/including.json"
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
      included_file_path = "#{layout_path}/_#{f}.json"
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