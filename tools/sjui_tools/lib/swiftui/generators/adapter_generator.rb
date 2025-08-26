# frozen_string_literal: true

require 'fileutils'
require_relative '../../core/logger'
require_relative '../../core/config_manager'

module SjuiTools
  module SwiftUI
    module Generators
      class AdapterGenerator
        def initialize(name, options = {})
          @name = name  # PascalCase name like TestComponent
          @adapter_class_name = "#{name}Adapter"
          @options = options
          @logger = Core::Logger
        end

        def generate
          @logger.info "Generating adapter for: #{@name}"
          
          # Determine adapter directory
          adapter_dir = get_adapter_directory
          
          if adapter_dir.nil?
            @logger.warn "No adapter_directory configured. Skipping adapter generation."
            @logger.info "Add 'adapter_directory: Extensions/Adapters' to sjui_config.yml to enable adapter generation."
            return false
          end
          
          # Create adapter file
          create_adapter_file(adapter_dir)
          
          # Update registration file if it exists
          update_registration_file(adapter_dir)
          
          @logger.success "Successfully generated adapter: #{@adapter_class_name}"
          true
        end
        
        private
        
        def get_adapter_directory
          # Load config using ConfigManager
          config = Core::ConfigManager.load_config
          
          # Check for adapter_directory in config
          adapter_dir = config['adapter_directory']
          source_dir = config['source_directory']
          
          if adapter_dir && !adapter_dir.strip.empty?
            # Check if we need to prepend source_directory
            # Only prepend if:
            # 1. source_dir is configured
            # 2. adapter_dir is not an absolute path
            # 3. Current working directory doesn't already end with source_dir
            current_dir_name = File.basename(Dir.pwd)
            if source_dir && !source_dir.strip.empty? && 
               !adapter_dir.start_with?('/') && 
               current_dir_name != source_dir
              return File.join(source_dir, adapter_dir)
            else
              return adapter_dir
            end
          end
          
          # Check for extension_directory as fallback
          extension_dir = config['extension_directory']
          if extension_dir && !extension_dir.strip.empty?
            current_dir_name = File.basename(Dir.pwd)
            if source_dir && !source_dir.strip.empty? && 
               !extension_dir.start_with?('/') && 
               current_dir_name != source_dir
              return File.join(source_dir, extension_dir, 'Adapters')
            else
              return File.join(extension_dir, 'Adapters')
            end
          end
          
          nil
        end
        
        def create_adapter_file(adapter_dir)
          # Ensure directory exists
          full_adapter_dir = File.join(Dir.pwd, adapter_dir)
          
          # Create directory if it doesn't exist
          unless File.directory?(full_adapter_dir)
            @logger.info "Creating adapter directory: #{full_adapter_dir}"
            FileUtils.mkdir_p(full_adapter_dir)
          end
          
          # Create adapter file
          adapter_file = File.join(full_adapter_dir, "#{@adapter_class_name}.swift")
          
          if File.exist?(adapter_file)
            @logger.warn "Adapter file already exists: #{adapter_file}"
            print "Overwrite? (y/n): "
            response = gets.chomp.downcase
            return unless response == 'y'
          end
          
          File.write(adapter_file, adapter_template)
          @logger.info "Created adapter file: #{adapter_file}"
        end
        
        def update_registration_file(adapter_dir)
          registration_file = File.join(Dir.pwd, adapter_dir, 'CustomComponentRegistration.swift')
          
          if File.exist?(registration_file)
            content = File.read(registration_file)
            
            # Check if adapter is already registered
            if content.include?("#{@adapter_class_name}()")
              @logger.info "Adapter already registered in CustomComponentRegistration.swift"
              return
            end
            
            # Add adapter to the list
            if content =~ /let adapters:\s*\[CustomComponentAdapter\]\s*=\s*\[(.*?)\]/m
              existing_adapters = $1
              new_adapter_list = existing_adapters.strip
              new_adapter_list += ",\n" unless new_adapter_list.empty?
              new_adapter_list += "            #{@adapter_class_name}()"
              
              new_content = content.sub(
                /let adapters:\s*\[CustomComponentAdapter\]\s*=\s*\[.*?\]/m,
                "let adapters: [CustomComponentAdapter] = [\n#{new_adapter_list}\n        ]"
              )
              
              File.write(registration_file, new_content)
              @logger.info "Updated CustomComponentRegistration.swift with #{@adapter_class_name}"
            end
          else
            # Create registration file if it doesn't exist
            File.write(registration_file, registration_template)
            @logger.info "Created CustomComponentRegistration.swift"
          end
        end
        
        def adapter_template
          attributes = parse_attributes
          
          <<~SWIFT
          //
          //  #{@adapter_class_name}.swift
          //  Generated adapter for #{@name}
          //

          import SwiftUI
          import SwiftJsonUI

          #if DEBUG

          struct #{@adapter_class_name}: CustomComponentAdapter {
              var componentType: String { "#{@name}" }
              
              func buildView(
                  component: DynamicComponent,
                  viewModel: DynamicViewModel,
                  viewId: String?,
                  parentOrientation: String?
              ) -> AnyView {
                  #{build_view_implementation(attributes)}
              }
          }

          #endif
          SWIFT
        end
        
        def build_view_implementation(attributes)
          if @options[:no_container]
            # Non-container component
            build_non_container_implementation(attributes)
          else
            # Container component
            build_container_implementation(attributes)
          end
        end
        
        def build_non_container_implementation(attributes)
          impl = "// Extract attributes from raw JSON data\n"
          
          attributes.each do |name, type|
            impl += "        let #{name} = "
            case type
            when 'String'
              impl += "component.rawData[\"#{name}\"] as? String ?? \"\"\n"
            when 'Bool'
              impl += "component.rawData[\"#{name}\"] as? Bool ?? false\n"
            when 'Int'
              impl += "component.rawData[\"#{name}\"] as? Int ?? 0\n"
            when 'Double'
              impl += "component.rawData[\"#{name}\"] as? Double ?? 0.0\n"
            when 'Float'
              impl += "component.rawData[\"#{name}\"] as? Float ?? 0.0\n"
            else
              impl += "component.rawData[\"#{name}\"] as? #{type}\n"
            end
          end
          
          impl += "\n        return AnyView(\n"
          impl += "            #{@name}(\n"
          
          # Add parameters
          param_lines = attributes.map { |name, _| "                #{name}: #{name}" }
          impl += param_lines.join(",\n")
          
          impl += "\n            )\n"
          impl += "        )"
          
          impl
        end
        
        def build_container_implementation(attributes)
          impl = "// Extract attributes from raw JSON data\n"
          
          attributes.each do |name, type|
            impl += "        let #{name} = "
            case type
            when 'String'
              impl += "component.rawData[\"#{name}\"] as? String ?? \"\"\n"
            when 'Bool'
              impl += "component.rawData[\"#{name}\"] as? Bool ?? false\n"
            when 'Int'
              impl += "component.rawData[\"#{name}\"] as? Int ?? 0\n"
            when 'Double'
              impl += "component.rawData[\"#{name}\"] as? Double ?? 0.0\n"
            when 'Float'
              impl += "component.rawData[\"#{name}\"] as? Float ?? 0.0\n"
            else
              impl += "component.rawData[\"#{name}\"] as? #{type}\n"
            end
          end
          
          impl += "\n        // Build the content from child components\n"
          impl += "        let content = VStack(alignment: .leading, spacing: 0) {\n"
          impl += "            if let children = component.childComponents {\n"
          impl += "                ForEach(Array(children.enumerated()), id: \\.offset) { _, child in\n"
          impl += "                    DynamicComponentBuilder(\n"
          impl += "                        component: child,\n"
          impl += "                        viewModel: viewModel,\n"
          impl += "                        viewId: viewId,\n"
          impl += "                        isWeightedChild: false,\n"
          impl += "                        parentOrientation: \"vertical\"\n"
          impl += "                    )\n"
          impl += "                }\n"
          impl += "            }\n"
          impl += "        }\n"
          
          impl += "\n        return AnyView(\n"
          impl += "            #{@name}(\n"
          
          # Add parameters
          param_lines = attributes.map { |name, _| "                #{name}: #{name}" }
          impl += param_lines.join(",\n")
          
          if !attributes.empty?
            impl += "\n"
          end
          impl += "            ) {\n"
          impl += "                content\n"
          impl += "            }\n"
          impl += "        )"
          
          impl
        end
        
        def parse_attributes
          return {} unless @options[:attributes]
          
          # Handle both string and hash formats
          if @options[:attributes].is_a?(Hash)
            # Already parsed as hash
            return @options[:attributes]
          elsif @options[:attributes].is_a?(String)
            # Parse attributes string like "text:String,isEnabled:Bool"
            attributes = {}
            @options[:attributes].split(',').each do |attr|
              parts = attr.strip.split(':')
              if parts.size == 2
                name = parts[0].strip
                type = parts[1].strip
                attributes[name] = type
              end
            end
            return attributes
          else
            return {}
          end
        end
        
        def registration_template
          <<~SWIFT
          //
          //  CustomComponentRegistration.swift
          //  Auto-generated registration file for custom component adapters
          //

          import SwiftUI
          import SwiftJsonUI

          #if DEBUG

          /// Helper to register all custom component adapters
          public struct CustomComponentRegistration {
              
              /// Register all custom component adapters with the registry
              public static func registerAll() {
                  let adapters: [CustomComponentAdapter] = [
                      #{@adapter_class_name}()
                  ]
                  
                  CustomComponentRegistry.shared.registerAll(adapters)
                  
                  print("✅ Registered \\(adapters.count) custom component adapters")
              }
          }

          #endif
          SWIFT
        end
      end
    end
  end
end