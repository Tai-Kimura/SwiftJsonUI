#!/usr/bin/env ruby

require "fileutils"
require_relative '../../../core/pbxproj_manager'

module SjuiTools
  module UIKit
    module XcodeProject
      module Generators
        class BaseBindingGenerator < ::SjuiTools::Core::PbxprojManager
          def initialize(project_file_path)
            super(project_file_path)
          end

          # directory_setup.rbから呼ばれる静的メソッド
          def self.check_or_generate(paths)
            ui_base_path = File.join(paths.core_path, "UI", "Base")
            file_path = File.join(ui_base_path, "BaseBinding.swift")
            
            if File.exist?(file_path)
              return true
            end
            
            # プロジェクトファイルパスを取得
            project_file_path = paths.instance_variable_get(:@project_file_path)
            generator = new(project_file_path)
            generator.generate(ui_base_path)
            return true
          rescue => e
            puts "Error generating BaseBinding: #{e.message}"
            return false
          end

          def generate(ui_base_path)
            file_path = File.join(ui_base_path, "BaseBinding.swift")
            
            # ファイルが既に存在する場合はスキップ
            if File.exist?(file_path)
              puts "BaseBinding.swift already exists, skipping creation"
              return nil
            end

            content = generate_content
            File.write(file_path, content)
            puts "Created BaseBinding: #{file_path}"
            file_path
          end

          private

          def generate_content
            <<~SWIFT
import UIKit
import SwiftJsonUI

@MainActor
class BaseBinding: Binding {
    // 初期化状態フラグ - 画面の初期化が完了したかを管理
//    var isInitialized: Bool = true
    
    // ナビゲーションタイトル文字列
//    var naviTitle: String?
    
    // ナビゲーションバーのビュー参照（weak参照でメモリリーク防止）
//    weak var navi: UIView!
    
    // タイトル表示用ラベルの参照（weak参照でメモリリーク防止）
//    weak var titleLabel: SJUILabel!
    
    // ナビゲーションタイトルの表示を更新するメソッド
    // リンク可能な場合はリンク付きテキスト、そうでなければ通常のテキストを適用
//    func invalidateNavi() {
//        titleLabel?.linkable ?? false ? titleLabel?.applyLinkableAttributedText(naviTitle) : titleLabel?.applyAttributedText(naviTitle)
//    }
}
            SWIFT
          end
        end
      end
    end
  end
end