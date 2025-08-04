#!/usr/bin/env ruby

require "fileutils"
require_relative '../pbxproj_manager'

class BaseBindingGenerator < PbxprojManager
  def initialize(project_file_path)
    super(project_file_path)
  end

  def generate(core_path)
    file_path = File.join(core_path, "BaseBinding.swift")
    
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