#!/usr/bin/env ruby

require "fileutils"
require_relative "../pbxproj_manager"

class BaseCollectionViewCellGenerator < PbxprojManager
  def initialize(project_file_path)
    super(project_file_path)
  end

  def generate(core_path)
    file_path = File.join(core_path, "BaseCollectionViewCell.swift")
    
    # ファイルが既に存在する場合はスキップ
    if File.exist?(file_path)
      puts "BaseCollectionViewCell.swift already exists, skipping creation"
      return nil
    end

    content = generate_content
    File.write(file_path, content)
    puts "Created BaseCollectionViewCell: #{file_path}"
    file_path
  end

  private

  def generate_content
    <<~SWIFT
import UIKit
import SwiftJsonUI

class BaseCollectionViewCell: SJUICollectionViewCell {
    
    // セルのインデックス位置を管理するプロパティ
    var index: Int = 0
    
    // プログラムで生成されるセルの初期化メソッド
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    // Storyboard/XIBから生成されるセルの初期化メソッド
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Auto Layoutでセルサイズを自動計算する際に呼ばれるメソッド
    // レイアウト属性をそのまま返すことで、Auto Layoutによるサイズ計算を有効にする
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return layoutAttributes
    }
}
    SWIFT
  end
end