#!/usr/bin/env ruby

require "fileutils"
require_relative '../pbxproj_manager'

module SjuiTools
  module Binding
    module XcodeProject
      module Generators
        class BaseBindingGenerator < ::SjuiTools::Binding::XcodeProject::PbxprojManager
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

open class BaseBinding: NSObject, Binding {
    
    public weak var viewHolder: ViewHolder?
    
    public required init(viewHolder: ViewHolder) {
        self.viewHolder = viewHolder
        super.init()
    }
    
    open func attachViewToProperty() {
        // Subclasses should override this method to attach views to properties
    }
    
    open func viewDidAppear() {
        // Subclasses can override if needed
    }
    
    open func viewWillAppear() {
        // Subclasses can override if needed
    }
    
    open func viewWillDisappear() {
        // Subclasses can override if needed
    }
    
    open func viewDidDisappear() {
        // Subclasses can override if needed
    }
    
    open func viewDidLayoutSubviews() {
        // Subclasses can override if needed
    }
}
            SWIFT
          end
        end
      end
    end
  end
end