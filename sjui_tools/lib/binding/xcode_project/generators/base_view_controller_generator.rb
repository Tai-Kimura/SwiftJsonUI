#!/usr/bin/env ruby

require "fileutils"
require_relative '../pbxproj_manager'

module SjuiTools
  module Binding
    module XcodeProject
      module Generators
        class BaseViewControllerGenerator < ::SjuiTools::Binding::XcodeProject::PbxprojManager
          def initialize(project_file_path)
            super(project_file_path)
          end

          # directory_setup.rbから呼ばれる静的メソッド
          def self.check_or_generate(paths)
            file_path = File.join(paths.core_path, "BaseViewController.swift")
            
            if File.exist?(file_path)
              return true
            end
            
            # プロジェクトファイルパスを取得
            project_file_path = paths.instance_variable_get(:@project_file_path)
            generator = new(project_file_path)
            generator.generate(paths.core_path)
            return true
          rescue => e
            puts "Error generating BaseViewController: #{e.message}"
            return false
          end

          def generate(core_path)
            file_path = File.join(core_path, "BaseViewController.swift")
            
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

open class BaseViewController: UIViewController, ViewHolder, UIGestureRecognizerDelegate {
    
    open var layoutPath: String {
        fatalError("Subclasses must override layoutPath")
    }
    
    open var binding: BaseBinding {
        fatalError("Subclasses must override binding")
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        // View setup will be done in subclasses
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        binding.viewWillAppear()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        binding.viewWillDisappear()
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        binding.viewDidDisappear()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        binding.viewDidAppear()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        binding.viewDidLayoutSubviews()
    }
    
    open func attachViewToProperty() {
        binding.attachViewToProperty()
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
            SWIFT
          end
        end
      end
    end
  end
end