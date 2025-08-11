# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'erb'
require_relative '../../core/config_manager'
require_relative '../../core/project_finder'

module SjuiTools
  module SwiftUI
    module Generators
      class CollectionGenerator
        def initialize(name)
          @name = name
          @snake_name = to_snake_case(name)
          @pascal_name = to_pascal_case(name)
          @config = Core::ConfigManager.load_config
          @project_root = Core::ProjectFinder.project_dir || Dir.pwd
          @src_root = Core::ProjectFinder.get_full_source_path
        end

        def generate
          puts "Generating SwiftUI collection cell: #{@pascal_name}"
          
          # Create directories
          create_directories
          
          # Generate files
          generate_json_layout
          generate_view_file
          generate_generated_view_file
          generate_data_file
          generate_view_model_file
          
          puts "\nGenerated SwiftUI collection cell:"
          puts "  JSON:          #{json_path}"
          puts "  Main View:     #{view_path}"
          puts "  Generated View: #{generated_view_path}"
          puts "  Data:          #{data_path}"
          puts "  ViewModel:     #{view_model_path}"
          puts "\nNext steps:"
          puts "  1. Edit the JSON layout in #{json_path}"
          puts "  2. Run 'sjui build' to generate the SwiftUI code"
        end

        private

        def create_directories
          FileUtils.mkdir_p(view_dir)
          FileUtils.mkdir_p(layouts_dir)
          FileUtils.mkdir_p(data_dir)
          FileUtils.mkdir_p(view_model_dir)
        end

        def generate_json_layout
          content = {
            type: "View",
            width: "matchParent",
            height: "wrapContent",
            padding: 10,
            background: "#FFFFFF",
            orientation: "vertical",
            child: [
              {
                data: [
                  {
                    name: "title",
                    class: "String",
                    defaultValue: "Item"
                  },
                  {
                    name: "subtitle",
                    class: "String",
                    defaultValue: "Description"
                  }
                ]
              },
              {
                type: "Label",
                text: "@{title}",
                fontSize: 16,
                font: "bold",
                fontColor: "#333333",
                bottomMargin: 4
              },
              {
                type: "Label",
                text: "@{subtitle}",
                fontSize: 12,
                fontColor: "#666666"
              }
            ]
          }
          
          File.write(json_path, JSON.pretty_generate(content))
        end

        def generate_view_file
          content = <<~SWIFT
            import SwiftUI
            import SwiftJsonUI
            import Combine

            struct #{@pascal_name}View: View {
                @StateObject private var viewModel: #{@pascal_name}ViewModel
                
                init(data: Any) {
                    let vm = #{@pascal_name}ViewModel()
                    vm.setData(data)
                    _viewModel = StateObject(wrappedValue: vm)
                }
                
                var body: some View {
                    #{@pascal_name}GeneratedView()
                        .environmentObject(viewModel)
                        // Add navigation destinations, sheets, or other view-level modifiers here
                }
            }

            // MARK: - Preview
            struct #{@pascal_name}View_Previews: PreviewProvider {
                static var previews: some View {
                    #{@pascal_name}View(data: [
                        "title": "Preview Item",
                        "subtitle": "Preview Description"
                    ])
                }
            }
          SWIFT
          
          File.write(view_path, content)
        end

        def generate_generated_view_file
          content = <<~SWIFT
            import SwiftUI
            import SwiftJsonUI
            import Combine

            struct #{@pascal_name}GeneratedView: View {
                @EnvironmentObject var viewModel: #{@pascal_name}ViewModel
                @StateObject private var dynamicViewModel = DynamicViewModel(jsonName: "#{@snake_name}")
                
                var body: some View {
                    if ViewSwitcher.isDynamicMode {
                        DynamicView(jsonName: "#{@snake_name}", viewId: "#{@snake_name}_view")
                            .environmentObject(dynamicViewModel)
                    } else {
                        // Generated SwiftUI code from #{@snake_name}.json
                        // This will be updated when you run 'sjui build'
                        // >>> GENERATED_CODE_START
                        Text("Run 'sjui build' to generate SwiftUI code")
                        // >>> GENERATED_CODE_END
                    }
                }
            }
          SWIFT
          
          File.write(generated_view_path, content)
        end

        def generate_data_file
          content = <<~SWIFT
            import Foundation
            import SwiftUI
            import SwiftJsonUI

            struct #{@pascal_name}Data {
                // Data properties from JSON
                var title: String = "Item"
                var subtitle: String = "Description"
                
                // Add more data properties as needed based on your JSON structure
            }
          SWIFT
          
          File.write(data_path, content)
        end

        def generate_view_model_file
          content = <<~SWIFT
            import Foundation
            import Combine
            import SwiftJsonUI

            class #{@pascal_name}ViewModel: ObservableObject {
                // JSON file reference for hot reload
                let jsonFileName = "#{@snake_name}"
                
                // Data model
                @Published var data = #{@pascal_name}Data()
                
                // Initialize with data from collection
                func setData(_ itemData: Any) {
                    if let dict = itemData as? [String: Any] {
                        data.title = dict["title"] as? String ?? data.title
                        data.subtitle = dict["subtitle"] as? String ?? data.subtitle
                    }
                }
                
                // Action handlers
                func onAppear() {
                    // Called when view appears
                }
                
                func onTap() {
                    // Handle tap events
                }
                
                // Add more action handlers as needed
            }
          SWIFT
          
          File.write(view_model_path, content)
        end

        # Path helpers
        def view_dir
          @view_dir ||= File.join(@src_root, 'View', @pascal_name)
        end

        def layouts_dir
          @layouts_dir ||= File.join(@src_root, 'Layouts')
        end

        def data_dir
          @data_dir ||= File.join(@src_root, 'Data')
        end

        def view_model_dir
          @view_model_dir ||= File.join(@src_root, 'ViewModel')
        end

        def json_path
          File.join(layouts_dir, "#{@snake_name}.json")
        end

        def view_path
          File.join(view_dir, "#{@pascal_name}View.swift")
        end

        def generated_view_path
          File.join(view_dir, "#{@pascal_name}GeneratedView.swift")
        end

        def data_path
          File.join(data_dir, "#{@pascal_name}Data.swift")
        end

        def view_model_path
          File.join(view_model_dir, "#{@pascal_name}ViewModel.swift")
        end

        # Name conversion helpers
        def to_snake_case(name)
          name.gsub(/::/, '/')
              .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
              .gsub(/([a-z\d])([A-Z])/, '\1_\2')
              .tr('-', '_')
              .downcase
        end

        def to_pascal_case(name)
          name.split(/[_\-\/]/).map(&:capitalize).join
        end
      end
    end
  end
end