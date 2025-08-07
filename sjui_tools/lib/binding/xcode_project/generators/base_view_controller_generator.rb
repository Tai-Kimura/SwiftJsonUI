#!/usr/bin/env ruby

require "fileutils"
require_relative '../../../core/pbxproj_manager'

module SjuiTools
  module Binding
    module XcodeProject
      module Generators
        class BaseViewControllerGenerator < ::SjuiTools::Core::PbxprojManager
          def initialize(project_file_path)
            super(project_file_path)
          end

          # directory_setup.rbから呼ばれる静的メソッド
          def self.check_or_generate(paths)
            base_path = File.join(paths.core_path, "UI", "Base")
            file_path = File.join(base_path, "BaseViewController.swift")
            
            if File.exist?(file_path)
              return true
            end
            
            # プロジェクトファイルパスを取得
            project_file_path = paths.instance_variable_get(:@project_file_path)
            generator = new(project_file_path)
            generator.generate(base_path)
            return true
          rescue => e
            puts "Error generating BaseViewController: #{e.message}"
            return false
          end

          def generate(base_path)
            file_path = File.join(base_path, "BaseViewController.swift")
            
            # ファイルが既に存在する場合はスキップ
            if File.exist?(file_path)
              puts "BaseViewController.swift already exists, skipping creation"
              return nil
            end

            content = generate_content
            File.write(file_path, content)
            puts "Created BaseViewController: #{file_path}"
            file_path
          end

          private

          def generate_content
            <<~SWIFT
import UIKit
import SwiftJsonUI

class BaseViewController: SJUIViewController {
    
    // ViewControllerの初期化状態を管理するフラグ
    var _initialized = false
    
    // レイアウトが完了したかを管理するフラグ
    var _viewDidLayout = false
    
    // ステータスバーの表示/非表示を管理するフラグ
    var _statusBarHidden = false
    
    // ViewControllerの一意識別子
    let uuid = UUID().uuidString
    
    // 遅延初期化されるバインディングオブジェクト
    private lazy var _binding: BaseBinding = BaseBinding(viewHolder: self)
    
    // バインディングオブジェクトへの読み取り専用アクセス
    var binding: BaseBinding {
        get {
            return _binding
        }
    }
    
    // レイアウトファイルのパスを返すプロパティ（サブクラスでオーバーライド）
    var layoutPath: String {
        get {
            return ""
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // iOS 7以降でのエッジ拡張レイアウトの設定
        if (self.responds(to: #selector(getter: UIViewController.edgesForExtendedLayout))){
            self.edgesForExtendedLayout = edgeStyle()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presentAction()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dismissAction()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if _viewDidLayout {
            return
        }
        layoutView()
    }
    
    // ViewController表示時の処理
    func presentAction() {
        self.view.layoutIfNeeded()
    }
    
    // ViewController非表示時の処理
    func dismissAction() {
    }
    
    // アプリがバックグラウンドに移行した際の処理
    @objc func applicationDidEnterBackground() {
        dismissAction()
    }
    
    // 現在のViewControllerが最前面に表示されているかを判定
    private func isTopViewController() -> Bool {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return false
        }
        
        var topViewController = window.rootViewController
        while let presentedViewController = topViewController?.presentedViewController {
            topViewController = presentedViewController
        }
        
        if let navigationController = topViewController as? UINavigationController {
            topViewController = navigationController.visibleViewController
        }
        
        if let tabBarController = topViewController as? UITabBarController {
            topViewController = tabBarController.selectedViewController
        }
        
        return topViewController == self
    }
    
    //    MARK: UI関連
    // エッジ拡張スタイルを定義（サブクラスでオーバーライド可能）
    func edgeStyle() -> UIRectEdge {
        return UIRectEdge()
    }
    
    // レイアウトをクリーンアップして再構築
    func cleanUpView(layoutPath: String) {
        for subView in self.view.subviews {
            subView.removeFromSuperview()
        }
        self._initialized = false
        self._viewDidLayout = false
        self._views.removeAll()
        self.view.addSubview(UIViewCreator.createView(layoutPath, target: self)!)
        self.attachViewToProperty()
        self.presentAction()
    }
    
    #if DEBUG
    // デバッグ時のレイアウトファイル変更検知処理
    override func layoutFileDidChanged() {
        super.layoutFileDidChanged()
        self._initialized = false
        self._viewDidLayout = false
        self._views.removeAll()
        for subview in self.view.subviews {
            subview.removeFromSuperview()
        }
        self.view.addSubview(UIViewCreator.createView(layoutPath, target: self)!)
        self.attachViewToProperty()
        if isTopViewController() {
            self.presentAction()
        }
    }
    #endif
    
    // ビューをプロパティにアタッチ
    func attachViewToProperty() {
        binding.bindView()
    }
    
    // レイアウト処理完了フラグの設定
    func layoutView() {
        _viewDidLayout = true
    }
    
    // ViewControllerの初期化処理
    func initialize() {
        _views = [String:UIView]()
        _initialized = false
        _viewDidLayout = false
    }
    
    // ステータスバーの表示/非表示制御
    override var prefersStatusBarHidden : Bool {
        return _statusBarHidden
    }
    
    // ステータスバーのアニメーション設定
    override var preferredStatusBarUpdateAnimation : UIStatusBarAnimation {
        return .fade
    }
    
    // 画面回転時の処理
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil, completion: {_ in
            self.view.subviews.first?.resetConstraintInfo(resetAllSubviews: true)
        })
    }
}
            SWIFT
          end
        end
      end
    end
  end
end