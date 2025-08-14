# frozen_string_literal: true

require 'json'
require 'fileutils'
require_relative '../../core/config_manager'
require_relative '../../core/project_finder'
require_relative '../../core/logger'

module SjuiTools
  module SwiftUI
    module Generators
      class ViewGenerator
        def initialize(name, options = {})
          @name = name
          @options = options
          @config = Core::ConfigManager.load_config
        end

        def generate
          # Parse name for subdirectories
          parts = @name.split('/')
          view_name = parts.last
          subdirectory = parts[0...-1].join('/') if parts.length > 1
          
          # Convert to proper case
          view_class_name = to_pascal_case(view_name)
          json_file_name = to_snake_case(view_name)
          
          # Get directories from config
          source_path = Core::ProjectFinder.get_full_source_path || Dir.pwd
          layouts_dir = @config['layouts_directory'] || 'Layouts'
          view_dir = @config['view_directory'] || 'View'
          viewmodel_dir = @config['viewmodel_directory'] || 'ViewModel'
          data_dir = @config['data_directory'] || 'Data'
          
          # Create full paths with subdirectory support
          if subdirectory
            json_path = File.join(source_path, layouts_dir, subdirectory)
            # Create folder for the view in View directory
            swift_path = File.join(source_path, view_dir, subdirectory, view_class_name)
            viewmodel_path = File.join(source_path, viewmodel_dir, subdirectory)
            data_path = File.join(source_path, data_dir, subdirectory)
          else
            json_path = File.join(source_path, layouts_dir)
            # Create folder for the view in View directory
            swift_path = File.join(source_path, view_dir, view_class_name)
            viewmodel_path = File.join(source_path, viewmodel_dir)
            data_path = File.join(source_path, data_dir)
          end
          
          # Create directories if they don't exist
          FileUtils.mkdir_p(json_path)
          FileUtils.mkdir_p(swift_path)
          FileUtils.mkdir_p(viewmodel_path)
          FileUtils.mkdir_p(data_path)
          
          # Create JSON file
          json_file = File.join(json_path, "#{json_file_name}.json")
          create_json_template(json_file, view_class_name)
          
          # Create Main View file (wrapper)
          main_swift_file = File.join(swift_path, "#{view_class_name}View.swift")
          create_main_view_template(main_swift_file, view_class_name, json_file_name, subdirectory)
          
          # Create Generated View file (for JSON generation)
          generated_swift_file = File.join(swift_path, "#{view_class_name}GeneratedView.swift")
          create_generated_view_template(generated_swift_file, view_class_name, json_file_name, subdirectory)
          
          # Create Data file
          data_file = File.join(data_path, "#{view_class_name}Data.swift")
          create_data_template(data_file, view_class_name)
          
          # Create ViewModel file
          viewmodel_file = File.join(viewmodel_path, "#{view_class_name}ViewModel.swift")
          create_viewmodel_template(viewmodel_file, view_class_name, json_file_name, subdirectory)
          
          # Update App.swift if --root option is specified
          if @options[:root]
            update_app_file(view_class_name)
          end
          
          Core::Logger.info "Generated SwiftUI view:"
          Core::Logger.info "  JSON:          #{json_file}"
          Core::Logger.info "  Main View:     #{main_swift_file}"
          Core::Logger.info "  Generated View: #{generated_swift_file}"
          Core::Logger.info "  Data:          #{data_file}"
          Core::Logger.info "  ViewModel:     #{viewmodel_file}"
          
          if @options[:root]
            Core::Logger.info "  Updated App.swift to use #{view_class_name}View as root"
          end
          
          Core::Logger.info ""
          Core::Logger.info "Next steps:"
          Core::Logger.info "  1. Edit the JSON layout in #{json_file}"
          Core::Logger.info "  2. Run 'sjui build' to generate the SwiftUI code"
        end

        private

        def to_pascal_case(str)
          # Handle camelCase and PascalCase input
          # First convert to snake_case, then to PascalCase
          snake = str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                     .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                     .downcase
          snake.split(/[_\-]/).map(&:capitalize).join
        end

        def to_snake_case(str)
          str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
             .gsub(/([a-z\d])([A-Z])/, '\1_\2')
             .downcase
        end

        def create_json_template(file_path, view_name)
          return if File.exist?(file_path)
          
          template = {
            type: "View",
            width: "matchParent",
            height: "matchParent",
            background: "#FFFFFF",
            orientation: "vertical",
            child: [
              {
                data: [
                  {
                    name: "title",
                    class: "String",
                    defaultValue: view_name
                  }
                ]
              },
              {
                type: "Label",
                id: "title_label",
                width: "wrapContent",
                height: "wrapContent",
                topMargin: 20,
                text: "@{title}",
                fontSize: 24,
                fontColor: "#000000"
              }
            ]
          }
          
          File.write(file_path, JSON.pretty_generate(template))
          Core::Logger.debug "Created JSON template: #{file_path}"
        end

        def update_app_file(view_name)
          source_path = Core::ProjectFinder.get_full_source_path || Dir.pwd
          
          # Find App.swift file
          app_files = Dir.glob(File.join(source_path, '**/*App.swift'))
          if app_files.empty?
            Core::Logger.warn "Could not find App.swift file to update"
            return
          end
          
          app_file = app_files.first
          content = File.read(app_file)
          
          # Update WindowGroup content
          # Match patterns like: WindowGroup { SomeView() }
          updated = false
          
          # Pattern 1: Empty WindowGroup
          if content =~ /WindowGroup\s*\{\s*\}/m
            content.gsub!(/WindowGroup\s*\{\s*\}/m, "WindowGroup {\n            #{view_name}View()\n        }")
            updated = true
          # Pattern 2: Direct view in WindowGroup
          elsif content =~ /WindowGroup\s*\{[^}]*\w+View\(\)[^}]*\}/m
            content.gsub!(/WindowGroup\s*\{[^}]*\}/m, "WindowGroup {\n            #{view_name}View()\n        }")
            updated = true
          # Pattern 3: View with modifiers
          elsif content =~ /WindowGroup\s*\{[^}]*\w+View\(\)[\s\S]*?\n\s*\}/m
            content.gsub!(/(WindowGroup\s*\{)[^}]*(\})/m, "\\1\n            #{view_name}View()\n        \\2")
            updated = true
          end
          
          if updated
            File.write(app_file, content)
            Core::Logger.debug "Updated #{app_file}"
          else
            Core::Logger.warn "Could not update App.swift automatically"
            Core::Logger.info "Please manually update your App.swift to use #{view_name}View()"
          end
        end
        
        def create_main_view_template(file_path, view_name, json_name, subdirectory)
          return if File.exist?(file_path)
          
          template = <<~SWIFT
            import SwiftUI
            import SwiftJsonUI
            import Combine

            struct #{view_name}View: View {
                @StateObject private var viewModel = #{view_name}ViewModel()
                
                var body: some View {
                    #{view_name}GeneratedView()
                        .environmentObject(viewModel)
                        // Add navigation destinations, sheets, or other view-level modifiers here
                }
            }

            // MARK: - Preview
            struct #{view_name}View_Previews: PreviewProvider {
                static var previews: some View {
                    #{view_name}View()
                }
            }
          SWIFT
          
          File.write(file_path, template)
          Core::Logger.debug "Created Main View template: #{file_path}"
        end
        
        def create_generated_view_template(file_path, view_name, json_name, subdirectory)
          return if File.exist?(file_path)
          
          # Determine the JSON path reference for loading
          json_reference = subdirectory ? "#{subdirectory}/#{json_name}" : json_name
          
          template = <<~SWIFT
            import SwiftUI
            import SwiftJsonUI
            import Combine

            struct #{view_name}GeneratedView: View {
                @EnvironmentObject var viewModel: #{view_name}ViewModel
                @StateObject private var dynamicViewModel = DynamicViewModel(jsonName: "#{json_reference}")
                
                var body: some View {
                    if ViewSwitcher.isDynamicMode {
                        DynamicView(jsonName: "#{json_reference}", viewId: "#{json_name}_view", data: viewModel.data.toDictionary())
                            .environmentObject(dynamicViewModel)
                    } else {
                        // Generated SwiftUI code from #{json_reference}.json
                        // This will be updated when you run 'sjui build'
                        // >>> GENERATED_CODE_START
                        VStack {
                            Text(viewModel.data.title)
                                .font(.title)
                                .padding()
                            
                            Text("Run 'sjui build' to generate SwiftUI code")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        // >>> GENERATED_CODE_END
                    }
                }
            }
          SWIFT
          
          File.write(file_path, template)
          Core::Logger.debug "Created Generated View template: #{file_path}"
        end
        
        def create_data_template(file_path, view_name)
          return if File.exist?(file_path)
          
          template = <<~SWIFT
            import Foundation
            import SwiftUI
            import SwiftJsonUI

            struct #{view_name}Data {
                // Data properties from JSON
                var title: String = "#{view_name}"
                
                // Add more data properties as needed based on your JSON structure
                
                // Update properties from dictionary
                mutating func update(dictionary: [String: Any]) {
                    if let value = dictionary["title"] {
                        if let stringValue = value as? String {
                            self.title = stringValue
                        }
                    }
                }
            }
          SWIFT
          
          File.write(file_path, template)
          Core::Logger.debug "Created Data template: #{file_path}"
        end
        
        def create_viewmodel_template(file_path, view_name, json_name, subdirectory)
          return if File.exist?(file_path)
          
          # Determine the JSON path reference for loading
          json_reference = subdirectory ? "#{subdirectory}/#{json_name}" : json_name
          
          template = <<~SWIFT
            import Foundation
            import Combine
            import SwiftJsonUI

            class #{view_name}ViewModel: ObservableObject {
                // JSON file reference for hot reload
                let jsonFileName = "#{json_reference}"
                
                // Data model
                @Published var data = #{view_name}Data()
                
                // Action handlers
                func onAppear() {
                    // Called when view appears
                }
                
                // Add more action handlers as needed
                func onTap() {
                    // Handle tap events
                }
            }
          SWIFT
          
          File.write(file_path, template)
          Core::Logger.debug "Created ViewModel template: #{file_path}"
        end
      end
    end
  end
end