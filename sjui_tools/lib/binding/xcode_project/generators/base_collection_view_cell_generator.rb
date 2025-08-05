#!/usr/bin/env ruby

require "fileutils"
require_relative '../pbxproj_manager'

module SjuiTools
  module Binding
    module XcodeProject
      module Generators
        class BaseCollectionViewCellGenerator < ::SjuiTools::Binding::XcodeProject::PbxprojManager
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

open class BaseCollectionViewCell: UICollectionViewCell, ViewHolder {
    
    open var layoutPath: String {
        fatalError("Subclasses must override layoutPath")
    }
    
    open var binding: BaseBinding {
        fatalError("Subclasses must override binding")
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        // Setup will be done in subclasses
    }
    
    open override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return layoutAttributes
    }
    
    open func attachViewToProperty() {
        binding.attachViewToProperty()
    }
}
            SWIFT
          end
        end
      end
    end
  end
end