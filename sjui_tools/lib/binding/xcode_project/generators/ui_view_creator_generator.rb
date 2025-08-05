#!/usr/bin/env ruby

require "fileutils"
require_relative '../pbxproj_manager'
require_relative '../../../core/config_manager'

module SjuiTools
  module Binding
    module XcodeProject
      module Generators
        class UIViewCreatorGenerator < ::SjuiTools::Binding::XcodeProject::PbxprojManager
          def initialize(project_file_path)
            super(project_file_path)
          end

          # directory_setup.rbから呼ばれる静的メソッド
          def self.check_or_generate(paths)
            file_path = File.join(paths.core_path, "UIViewCreator.swift")
            
            if File.exist?(file_path)
              return true
            end
            
            # プロジェクトファイルパスを取得
            project_file_path = paths.instance_variable_get(:@project_file_path)
            generator = new(project_file_path)
            generator.generate(paths.core_path)
            return true
          rescue => e
            puts "Error generating UIViewCreator: #{e.message}"
            return false
          end

          def generate(core_path)
            file_path = File.join(core_path, "UIViewCreator.swift")
            
            # ファイルが既に存在する場合はスキップ
            if File.exist?(file_path)
              puts "UIViewCreator.swift already exists, skipping creation"
              return nil
            end

            content = generate_content
            File.write(file_path, content)
            puts "Created UIViewCreator: #{file_path}"
            file_path
          end

          private

          def generate_content
            # Load config values
            base_dir = File.expand_path('../..', File.dirname(__FILE__))
            config = Core::ConfigManager.load_config(base_dir)
            
            layouts_dir = config['layouts_directory'] || 'Layouts'
            styles_dir = config['styles_directory'] || 'Styles'
            bindings_dir = config['bindings_directory'] || 'Bindings'
            view_dir = config['view_directory'] || 'View'
            
            <<~SWIFT
import UIKit
import SwiftJsonUI
import WebKit

@MainActor
class UIViewCreator: SJUIViewCreator {
    
    nonisolated override init() {
        super.init()
    }
    
    @MainActor
    open override class func getOnView(target: ViewHolder) -> UIView? {
        if let viewController = target as? BaseViewController {
            return viewController.view
        } else if let collectionViewCell = target as? BaseCollectionViewCell {
            return collectionViewCell.contentView
        } else if let collectionViewHeader = target as? SJUICollectionReusableView {
            return collectionViewHeader
        } else {
            return super.getOnView(target: target)
        }
    }
    
    @MainActor
    override class func getViewFromJSON(attr: JSON, target: Any, views: inout [String: UIView]) -> UIView? {
        let view: UIView?
        switch(attr["type"].stringValue) {
        case "Web":
            let configuration = WKWebViewConfiguration()
            view = WKWebView(frame: CGRect.zero, configuration: configuration)
        default:
            view = super.getViewFromJSON(attr: attr, target: target, views: &views)
        }
        return view
    }
    
    @MainActor
    class func prepare() {
        // Directory configuration from config.json
        SJUIViewCreator.layoutsDirectoryName = "#{layouts_dir}"
        SJUIViewCreator.stylesDirectoryName = "#{styles_dir}"
        SJUIViewCreator.scriptsDirectoryName = "Scripts"
        
        // サンプル設定 - 実際のプロジェクトに合わせて調整してください
        String.currentLanguage = "ja-JP"
        defaultFont = "System"
        defaultFontColor = UIColor.label
        defaultHintColor = UIColor.secondaryLabel
        defaultFontSize = 14.0
        // カラーIDに基づく色の検索機能（サンプル実装）
//        findColorFunc = {arg in
//            if let intValue = arg as? Int {
//                // 実際のプロジェクトではカラーIDに応じた色を返す
//                switch intValue {
//                case 1: return UIColor.systemBlue
//                case 2: return UIColor.systemRed
//                case 3: return UIColor.systemGreen
//                default: return UIColor.label
//                }
//            }
//            return nil
//        }
        SJUILabel.defaultLinkColor = UIColor.link
        
        // フォントによる文字の上下位置補正（サンプル実装）
        // 特定のフォントでは文字が切れることがあるため、垂直位置を調整する
//        if #available(iOS 17.0, *) {
//            // iOS 17以降での補正値（HiraginoSansの場合）
//            SJUILabel.verticalAdjustmentByFonts["HiraginoSans-W3"] = 21.0
//            SJUILabel.verticalAdjustmentByFonts["HiraginoSans-W6"] = 21.0
//        } else {
//            // iOS 16以前での補正値（HiraginoSansの場合）
//            SJUILabel.verticalAdjustmentByFonts["HiraginoSans-W3"] = 7.0
//            SJUILabel.verticalAdjustmentByFonts["HiraginoSans-W6"] = 7.0
//        }
        SJUIRadioButton.defaultOnColor = UIColor.systemBlue
        SJUITextField.accessoryBackgroundColor = UIColor.systemGray6
        SJUITextField.accessoryTextColor = UIColor.link
        SJUITextField.defaultBorderColor = UIColor.lightGray
        SJUISegmentedControl.defaultTintColor = UIColor.systemGray
        SJUISegmentedControl.defaultSelectedColor = UIColor.white
        SJUIRadioButton.defaultOffColor = UIColor.systemGray
        SJUIRadioButton.defaultOnColor = UIColor.systemBlue
        SJUISelectBox.defaultCaretImageName = "chevron.down"
        SJUISelectBox.defaultReferenceViewId = "scroll_view"
        // SheetView の設定例
        // SheetView.lineColor = UIColor.systemGray4
        // SheetView.font = UIFont.systemFont(ofSize: 20.0)
        // SheetView.textColor = UIColor.label
    }
}
    SWIFT
          end
        end
      end
    end
  end
end