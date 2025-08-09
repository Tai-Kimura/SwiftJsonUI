# frozen_string_literal: true

require 'json'
require 'fileutils'
require_relative '../../core/config_manager'
require_relative '../../core/project_finder'

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
          
          # Create full paths with subdirectory support
          if subdirectory
            json_path = File.join(source_path, layouts_dir, subdirectory)
            swift_path = File.join(source_path, view_dir, subdirectory)
          else
            json_path = File.join(source_path, layouts_dir)
            swift_path = File.join(source_path, view_dir)
          end
          
          # Create directories if they don't exist
          FileUtils.mkdir_p(json_path)
          FileUtils.mkdir_p(swift_path)
          
          # Create JSON file
          json_file = File.join(json_path, "#{json_file_name}.json")
          create_json_template(json_file, view_class_name)
          
          # Create Swift file
          swift_file = File.join(swift_path, "#{view_class_name}View.swift")
          create_swift_template(swift_file, view_class_name, json_file_name, subdirectory)
          
          puts "Generated SwiftUI view:"
          puts "  JSON:  #{json_file}"
          puts "  Swift: #{swift_file}"
          puts
          puts "Next steps:"
          puts "  1. Edit the JSON layout in #{json_file}"
          puts "  2. Run 'sjui build' to generate the SwiftUI code"
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
          puts "Created JSON template: #{file_path}"
        end

        def create_swift_template(file_path, view_name, json_name, subdirectory)
          return if File.exist?(file_path)
          
          # Determine the JSON path reference for loading
          json_reference = subdirectory ? "#{subdirectory}/#{json_name}" : json_name
          
          template = <<~SWIFT
            import SwiftUI
            import SwiftJsonUI
            import Combine

            struct #{view_name}View: View {
                @StateObject private var viewModel = #{view_name}ViewModel()
                
                var body: some View {
                    generatedBody
                }
                
                // Generated SwiftUI code from #{json_reference}.json
                // This will be updated when you run 'sjui build'
                @ViewBuilder
                private var generatedBody: some View {
                    // TODO: Run 'sjui build' to generate SwiftUI code from JSON
                    VStack {
                        Text(viewModel.title)
                            .font(.title)
                            .padding()
                        
                        Text("Generated from #{json_reference}.json")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }

            class #{view_name}ViewModel: ObservableObject {
                // JSON file reference for hot reload
                let jsonFileName = "#{json_reference}"
                
                // Data properties from JSON
                @Published var title: String = "#{view_name}"
                
                // Action handlers
                func onAppear() {
                    // Called when view appears
                }
                
                // Add more action handlers as needed
                func onTap() {
                    // Handle tap events
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
          puts "Created Swift template: #{file_path}"
        end
      end
    end
  end
end