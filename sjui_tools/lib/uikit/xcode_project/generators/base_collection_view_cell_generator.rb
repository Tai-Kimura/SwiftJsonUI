#!/usr/bin/env ruby

require "fileutils"
require_relative '../../../core/pbxproj_manager'

module SjuiTools
  module UIKit
    module XcodeProject
      module Generators
        class BaseCollectionViewCellGenerator < ::SjuiTools::Core::PbxprojManager
          def initialize(project_file_path)
            super(project_file_path)
          end

          # directory_setup.rbから呼ばれる静的メソッド
          def self.check_or_generate(paths)
            ui_base_path = File.join(paths.core_path, "UI", "Base")
            file_path = File.join(ui_base_path, "BaseCollectionViewCell.swift")
            
            if File.exist?(file_path)
              return true
            end
            
            # プロジェクトファイルパスを取得
            project_file_path = paths.instance_variable_get(:@project_file_path)
            generator = new(project_file_path)
            generator.generate(ui_base_path)
            return true
          rescue => e
            puts "Error generating BaseCollectionViewCell: #{e.message}"
            return false
          end

          def generate(ui_base_path)
            file_path = File.join(ui_base_path, "BaseCollectionViewCell.swift")
            
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
      end
    end
  end
end