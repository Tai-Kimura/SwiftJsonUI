#!/usr/bin/env ruby

require "fileutils"

module SjuiTools
  module Binding
    module XcodeProject
      module Setup
        class AppDelegateSetup
          def initialize(project_file_path)
            @project_file_path = project_file_path
          end

          def add_hotloader_functionality
            puts "Adding HotLoader functionality to AppDelegate..."
            
            # AppDelegate.swiftファイルを探す
            # @project_file_pathが.xcodeprojかproject.pbxprojかを確認
            if @project_file_path.end_with?('.pbxproj')
              # project.pbxprojの場合は2階層上がプロジェクトディレクトリ
              project_dir = File.dirname(File.dirname(File.dirname(@project_file_path)))
            else
              # .xcodeprojディレクトリの場合は親ディレクトリがプロジェクトディレクトリ
              project_dir = File.dirname(@project_file_path)
            end
            
            app_delegate_path = find_app_delegate_file(project_dir)
            
            if app_delegate_path.nil?
              puts "Warning: Could not find AppDelegate.swift file. HotLoader functionality not added."
              return
            end

            puts "Updating AppDelegate: #{app_delegate_path}"
            
            # AppDelegate.swiftの内容を読み込む
            content = File.read(app_delegate_path)
            
            # 既にHotLoader機能が追加されているかチェック
            if content.include?("HotLoader.instance")
              puts "HotLoader functionality already exists in AppDelegate"
              return
            end
            
            # AppDelegate.swiftにHotLoader機能を追加
            updated_content = add_hotloader_content(content)
            
            # ファイルに書き戻す
            File.write(app_delegate_path, updated_content)
            puts "HotLoader functionality added to AppDelegate successfully"
          end

          private

          def find_app_delegate_file(project_dir)
            # プロジェクトディレクトリから再帰的にAppDelegate.swiftを検索
            # ただし、DerivedData、Build、Pods、Carthageなどのディレクトリは除外
            app_delegate_files = Dir.glob("#{project_dir}/**/AppDelegate.swift").reject do |path|
              path.include?('DerivedData') || 
              path.include?('Build') || 
              path.include?('Pods') || 
              path.include?('Carthage') ||
              path.include?('.build') ||
              path.include?('node_modules')
            end
            
            # 最もプロジェクトルートに近いものを選択
            app_delegate_files.min_by { |path| path.split('/').length }
          end

          def add_hotloader_content(content)
            # import文を追加
            unless content.include?("import SwiftJsonUI")
              content = content.gsub(/^import UIKit/, "import UIKit\nimport SwiftJsonUI")
            end
            
            # 既存のHotLoader関連メソッドを削除（重複を防ぐため）
            content = remove_existing_hotloader_methods(content)
            
            # application(_:didFinishLaunchingWithOptions:)メソッドにHotLoader初期化を追加
            content = add_hotloader_to_did_finish_launching(content)
            
            # ライフサイクルメソッドを1つずつ安全に追加
            content = add_lifecycle_method_if_missing(content, "applicationDidBecomeActive", generate_did_become_active_method)
            content = add_lifecycle_method_if_missing(content, "applicationDidEnterBackground", generate_did_enter_background_method)
            content = add_lifecycle_method_if_missing(content, "applicationWillTerminate", generate_will_terminate_method)
            
            content
          end

          def remove_existing_hotloader_methods(content)
            # HotLoader関連のコードを含む重複したメソッドを削除
            content = content.gsub(/func applicationDidBecomeActive\([^{]*\{\s*#if DEBUG\s*HotLoader\.instance\.isHotLoadEnabled = true\s*#endif[^}]*\}/, '')
            content = content.gsub(/func applicationDidEnterBackground\([^{]*\{\s*#if DEBUG\s*HotLoader\.instance\.isHotLoadEnabled = false\s*#endif[^}]*\}/, '')
            content = content.gsub(/func applicationWillTerminate\([^{]*\{\s*#if DEBUG\s*HotLoader\.instance\.isHotLoadEnabled = false\s*#endif[^}]*\}/, '')
            
            # 不正な形式の関数定義を削除
            content = content.gsub(/func application\w+\([^{]*\{\s*#if DEBUG[^}]*(?:func \w+\([^}]*)*/, '')
            
            content
          end

          def add_hotloader_to_did_finish_launching(content)
            # application(_:didFinishLaunchingWithOptions:)メソッドを探す
            did_finish_pattern = /(func application\([^)]+didFinishLaunchingWithOptions[^{]*\{)/
            
            if content.match(did_finish_pattern)
              # 既存のメソッド内にUIViewCreator初期化が既にあるかチェック
              if content.include?("UIViewCreator.prepare()") && content.include?("HotLoader.instance.isHotLoadEnabled")
                return content
              end
              
              # 既存のメソッドにUIViewCreator初期化とHotLoader初期化を追加（最初の行に）
              content.gsub(did_finish_pattern) do |match|
                additions = []
                additions << "        UIViewCreator.prepare()" unless content.include?("UIViewCreator.prepare()")
                additions << "        UIViewCreator.copyResourcesToDocuments()" unless content.include?("UIViewCreator.copyResourcesToDocuments()")
                unless content.include?("HotLoader.instance.isHotLoadEnabled")
                  additions << "        #if DEBUG"
                  additions << "        HotLoader.instance.isHotLoadEnabled = true"
                  additions << "        #endif"
                end
                
                if additions.any?
                  "#{match}\n#{additions.join("\n")}"
                else
                  match
                end
              end
            else
              # メソッドが存在しない場合は新規作成
              add_method_to_class_safely(content, generate_did_finish_launching_method)
            end
          end

          def add_lifecycle_method_if_missing(content, method_name, method_code)
            # メソッドが既に存在するかチェック（より厳密に）
            method_pattern = /func\s+#{method_name}\s*\([^)]*\)\s*\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}/m
            
            unless content.match(method_pattern)
              # メソッドが存在しない場合のみ追加
              content = add_method_to_class_safely(content, method_code)
            end
            
            content
          end

          def generate_did_finish_launching_method
            <<~SWIFT.strip
              func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
                  UIViewCreator.prepare()
                  UIViewCreator.copyResourcesToDocuments()
                  #if DEBUG
                  HotLoader.instance.isHotLoadEnabled = true
                  #endif
                  // Override point for customization after application launch.
                  return true
              }
            SWIFT
          end

          def generate_did_become_active_method
            <<~SWIFT.strip
              func applicationDidBecomeActive(_ application: UIApplication) {
                  #if DEBUG
                  HotLoader.instance.isHotLoadEnabled = true
                  #endif
              }
            SWIFT
          end

          def generate_did_enter_background_method
            <<~SWIFT.strip
              func applicationDidEnterBackground(_ application: UIApplication) {
                  #if DEBUG
                  HotLoader.instance.isHotLoadEnabled = false
                  #endif
              }
            SWIFT
          end

          def generate_will_terminate_method
            <<~SWIFT.strip
              func applicationWillTerminate(_ application: UIApplication) {
                  #if DEBUG
                  HotLoader.instance.isHotLoadEnabled = false
                  #endif
              }
            SWIFT
          end

          def add_method_to_class_safely(content, method_code)
            # より安全なアプローチ：クラスの最後の行を見つけて追加
            lines = content.lines
            
            # 最後の非空行のインデックスを見つける
            last_content_index = -1
            lines.reverse_each.with_index do |line, reverse_index|
              if line.strip.length > 0
                last_content_index = lines.length - 1 - reverse_index
                break
              end
            end
            
            # クラスの終端 } を見つける
            class_end_index = nil
            (last_content_index..lines.length-1).each do |i|
              if lines[i] && lines[i].strip == "}"
                class_end_index = i
                break
              end
            end
            
            if class_end_index
              # メソッドを正しいインデントで整形
              formatted_lines = []
              method_code.lines.each do |line|
                if line.strip.empty?
                  formatted_lines << ""
                else
                  formatted_lines << "    #{line.chomp}"
                end
              end
              formatted_lines << ""  # 1行の空行のみ
              
              # クラス終端の前に挿入
              formatted_lines.reverse_each do |formatted_line|
                lines.insert(class_end_index, "#{formatted_line}\n")
              end
              
              lines.join
            else
              # クラス終端が見つからない場合はそのまま返す
              content
            end
          end
        end
      end
    end
  end
end

# コマンドライン実行
if __FILE__ == $0
  if ARGV.length != 1
    puts "Usage: ruby app_delegate_setup.rb <project_file_path>"
    puts "Example: ruby app_delegate_setup.rb /path/to/project.pbxproj"
    exit 1
  end

  project_file_path = ARGV[0]
  
  begin
    setup = SjuiTools::Binding::XcodeProject::Setup::AppDelegateSetup.new(project_file_path)
    setup.add_hotloader_functionality
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end